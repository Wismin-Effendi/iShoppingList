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

    var fetchedResultsProvider: FetchedResultsProvider<GroceryItems>!
    var dataSource: TableViewDataSource<TaskItemCell, GroceryItems>!
    var coreDataStack: CoreDataStack!
    var managedObjectContext: NSManagedObjectContext!
    var storeName: String!
    var storeNameAndNotPendingDeletionPredicate: NSPredicate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = storeName
        let storeNamePredicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.storeName.title),storeName)
        let notPendingDeletionPredicate = NSPredicate(format: "%K == NO", #keyPath(GroceryItems.pendingDeletion))
        storeNameAndNotPendingDeletionPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [storeNamePredicate, notPendingDeletionPredicate])
        populateGroceryItems(predicate: storeNameAndNotPendingDeletionPredicate)
    }
    
    private func populateGroceryItems(predicate: NSPredicate) {
        
        self.fetchedResultsProvider = FetchedResultsProvider<GroceryItems>(managedObjectContext: self.managedObjectContext,
                                                                           additionalPredicate: predicate)
        
        self.dataSource = TableViewDataSource(cellIdentifier: "GroceryItemsTableViewCell",
                                              tableView: self.tableView,
                                              fetchedResultsProvider: self.fetchedResultsProvider)
        { cell, model in
            cell.titleLabel?.text = model.title
            cell.itemIdentifier = model.identifier
            cell.completed = model.isCompleted
            cell.backgroundColor = UIColor.green
            cell.accessoryType = .detailButton
            cell.delegate = self   // for ItemCellCompletionStateDelegate
        }
        
        self.tableView.dataSource = self.dataSource
    }
    
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let addNewItemView = AddNewItemView(controller: self, placeHolderText: "Enter New Grocery Item") { (title) in
            
            self.addNewGroceryItem(title: title)
        }
                
        return addNewItemView
    }

    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 96
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return FilterItemView(controller: self) {[weak self] (category) in
            self?.filterItemsBy(category: category)
        }
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
        guard let shoppingList = CoreDataUtil.getShoppingListOf(storeName: self.storeName, moc: managedObjectContext) else {
            fatalError("Cannot save new item to non existing Shopping List")
        }
        
        let groceryItem = GroceryItems(context: self.managedObjectContext)
        groceryItem.title = title
        groceryItem.identifier = UUID().uuidString        
        groceryItem.pendingDeletion = false
        groceryItem.isRepeatedItem = false
        groceryItem.isCompleted = false
        groceryItem.completionDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        groceryItem.reminderDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        shoppingList.addToItems(groceryItem)
        
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
            let categoryPredicate = NSPredicate(format: "%K == NO", #keyPath(GroceryItems.isCompleted))
            combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [storeNameAndNotPendingDeletionPredicate,categoryPredicate])
        case .completed:
            let categoryPredicate = NSPredicate(format: "%K == YES", #keyPath(GroceryItems.isCompleted))
            combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [storeNameAndNotPendingDeletionPredicate,categoryPredicate])
        }
        populateGroceryItems(predicate: combinedPredicate)
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


extension GroceryItemsTableViewController: ItemCellCompletionStateDelegate {
    func persist(identifier: String, completed: Bool) {
        let currentItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.identifier), identifier)
        
        do {
            let results = try managedObjectContext.fetch(currentItemFetch)
            if let item = results.first {
                item.isCompleted = completed
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
    
    func cloneToWarehouseIfRepeatedItem(identifier: String, completed: Bool) {
        guard completed else { return }
        
        coreDataStack.performBackgroundTask { (backgroundContext) in
           _ = CloneItemToWarehouse(identifier: identifier, moc: backgroundContext)
        }
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
