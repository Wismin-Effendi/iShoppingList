//
//  GroceryItemsTableViewController.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData

class GroceryItemsTableViewController: UITableViewController, UITextFieldDelegate {

    var fetchedResultsProvider: FetchedResultsProvider<GroceryItem>!
    var dataSource: TableViewDataSource<TaskItemCell, GroceryItem>!
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
            cell.titleLabel?.text = model.title
            cell.itemIdentifier = model.identifier
            cell.completed = model.completed
            cell.backgroundColor = UIColor.green
            cell.accessoryType = .detailButton
            cell.delegate = strongSelf   // for ItemCellCompletionStateDelegate
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
        detailViewController.itemIdentifier = tableCell.itemIdentifier
        
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
        shoppingList.addToItems(groceryItem)
        groceryItem.storeName = shoppingList
        groceryItem.title = title
        groceryItem.identifier = UUID().uuidString        
        groceryItem.pendingDeletion = false
        groceryItem.isRepeatedItem = false
        groceryItem.completed = false
        groceryItem.completionDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        groceryItem.reminderDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        
        
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save new grocery item to core data. \(error.localizedDescription)")
        }
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
    func persist(identifier: String, completed: Bool) {
        let currentItemFetch: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.identifier), identifier)
        
        do {
            let results = try managedObjectContext.fetch(currentItemFetch)
            if let item = results.first {
                item.completed = completed
                if completed {
                    item.completionDate = Date.init() as NSDate
                    item.hasReminder = false 
                }
                try self.managedObjectContext.save()
            }
        } catch let error as NSError {
            fatalError("Failed to save updated item. \(error.localizedDescription)")
        }
    }
    
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
