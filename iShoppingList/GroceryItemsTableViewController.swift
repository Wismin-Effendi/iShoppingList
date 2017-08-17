//
//  GroceryItemsTableViewController.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class GroceryItemsTableViewController: UITableViewController, UITextFieldDelegate {

    var fetchedResultsProvider: FetchedResultsProvider<GroceryItem>!
    var dataSource: TableViewDataSource<TaskItemCell, GroceryItem>!
    var cloudKitHelper: CloudKitHelper!
    var coreDataStack: CoreDataStack!
    var managedObjectContext: NSManagedObjectContext!
    var storeIdentifier: String!
    var storeNameTitle: String!
    var storeIdentifierAndNotPendingDeletionPredicate: NSPredicate!
    
    var currentItemsFilter = ItemsFilter.todo
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = storeNameTitle
        let filterItemTitle = UIBarButtonItem(title: ItemsFilter.completed.rawValue, style: .plain, target: self, action: #selector(GroceryItemsTableViewController.filterItems))
        navigationItem.rightBarButtonItem = filterItemTitle
        let storeIdentifierPredicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.storeName.identifier), storeIdentifier)
        let notPendingDeletionPredicate = NSPredicate(format: "%K == NO", #keyPath(GroceryItem.pendingDeletion))
        storeIdentifierAndNotPendingDeletionPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [storeIdentifierPredicate, notPendingDeletionPredicate])
        populateGroceryItems(predicate: storeIdentifierAndNotPendingDeletionPredicate)
        filterItemsBy(category: ItemCategory.todo)
        setupRefreshControl()
        saveToCloudKit()
    }
    
    func saveToCloudKit() {
        cloudKitHelper.savingToCloudKitOnly()
        refreshControl?.endRefreshing()
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Saving to iCloud")
        refreshControl!.addTarget(self, action: #selector(GroceryItemsTableViewController.saveToCloudKit), for: .valueChanged)
        tableView.addSubview(refreshControl!)
    }
    
    
    func filterItems(_ sender: UIBarButtonItem) {
        if let title = sender.title,
            let itemsFilter = ItemsFilter(rawValue: title) {
            switch itemsFilter {
            case .todo:
                currentItemsFilter = .todo
                sender.title = ItemsFilter.completed.rawValue
                filterItemsBy(category: ItemCategory.todo)
            case .completed:
                currentItemsFilter = .completed
                sender.title = ItemsFilter.todo.rawValue
                filterItemsBy(category: ItemCategory.completed)
            }
        }
    }
    
    private func populateGroceryItems(predicate: NSPredicate) {
        
        self.fetchedResultsProvider = FetchedResultsProvider<GroceryItem>(managedObjectContext: self.managedObjectContext,
                                                                           additionalPredicate: predicate)
        
        self.dataSource = TableViewDataSource(cellIdentifier: "GroceryItemsTableViewCell",
                                              tableView: self.tableView,
                                              fetchedResultsProvider: self.fetchedResultsProvider)
        {[weak self] cell, model in
            guard let strongSelf = self else { return }
            cell.model = model
            cell.titleLabel?.text = model.title
            cell.completed = model.completed
            cell.backgroundColor = UIColor.green
            cell.accessoryType = .detailButton
            cell.delegate = strongSelf   // for ItemCellCompletionStateDelegate
            print("Title: \(model.title)")
            print("Identifier: \(model.identifier)")
        }
        
        self.tableView.dataSource = self.dataSource
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return currentItemsFilter == .todo ?  44 : 0
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let addNewItemView = AddNewItemView(controller: self, placeHolderText: "Enter New Grocery Item") { (title) in
            
            self.addNewGroceryItem(title: title)
        }
                
        return addNewItemView
    }
    
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let tableCell = tableView.cellForRow(at: indexPath) as? TaskItemCell  else { return }

        var accessoryView = tableCell.accessoryView
        if accessoryView == nil {
            for subView in tableCell.subviews {
                if let button = subView as? UIButton {
                    accessoryView = button
                    break
                }
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailViewController = storyboard.instantiateViewController(withIdentifier: "ItemDetailsTableViewController") as! ItemDetailsTableViewController
        
        detailViewController.coreDataStack = coreDataStack 
        detailViewController.managedObjectContext = managedObjectContext
        detailViewController.item = tableCell.model
        
        detailViewController.itemIdentifier = "somePlaceholder_for_now"
        
        detailViewController.modalPresentationStyle = .popover
        let popover: UIPopoverPresentationController = detailViewController.popoverPresentationController!
        popover.sourceView = accessoryView
        popover.sourceRect = accessoryView!.bounds
        popover.delegate = self
        present(detailViewController, animated: true, completion: nil)
    }

    
    
    // MARK: Private
    
    private func addNewGroceryItem(title: String) {
        guard let shoppingList = CoreDataUtil.getAShoppingListOf(storeIdentifier: storeIdentifier, moc: managedObjectContext) else {
            fatalError("Cannot save new item to non existing Shopping List")
        }
        
        let groceryItem = GroceryItem(context: self.managedObjectContext)
        groceryItem.setDefaultValuesForLocalCreation()
        groceryItem.title = title
        groceryItem.identifier = UUID().uuidString
        // We only need to set storeName with reference to ShoppingList items, no need to also add groceryItem to ShoppingList item 
        // The CoreData would do that part for us since we have configure inverse relationship
        shoppingList.addToItems(groceryItem)
        try! self.managedObjectContext.save()
        self.managedObjectContext.refreshAllObjects()
    
    }
    
    private func filterItemsBy(category: ItemCategory) {
        let combinedPredicate: NSPredicate
        
        switch category {
        case .todo:
            let categoryPredicate = NSPredicate(format: "%K == NO", #keyPath(GroceryItem.completed))
            combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [storeIdentifierAndNotPendingDeletionPredicate,categoryPredicate])
        case .completed:
            let categoryPredicate = NSPredicate(format: "%K == YES", #keyPath(GroceryItem.completed))
            combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [storeIdentifierAndNotPendingDeletionPredicate,categoryPredicate])
        }
        populateGroceryItems(predicate: combinedPredicate)
        tableView.reloadSections([0], with: UITableViewRowAnimation.automatic)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


extension GroceryItemsTableViewController: ItemCellCompletionStateDelegate {
    
    func cloneToWarehouseIfRepeatedItem(identifier: String) {
        guard let item = CoreDataUtil.getGroceryItem(identifier: identifier, moc: coreDataStack.newBackgroundContext()), item.isRepeatedItem else { return }
        
        let backgroundContext = coreDataStack.newBackgroundContext()
        _ = CloneItemToWarehouse(identifier: identifier, moc: backgroundContext, completion: { print("cloning finished") } )
        
    }
}



extension GroceryItemsTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(GroceryItemsTableViewController.dismissPopoverViewController))
        navigationController.topViewController?.navigationItem.leftBarButtonItem = cancelButton
        
        return navigationController
    }
    
    // MARK: - Helper
    func dismissPopoverViewController() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension GroceryItemsTableViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
