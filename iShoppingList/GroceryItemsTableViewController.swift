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
    var managedObjectContext: NSManagedObjectContext!
    var storeName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = storeName
        populateGroceryItems()
    }
    
    private func populateGroceryItems() {
        
        self.fetchedResultsProvider = FetchedResultsProvider<GroceryItems>(managedObjectContext: self.managedObjectContext,
                                                                           forItemsOf: storeName)
        
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

    // Add empty view as footer to hide the extra rows
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.zero)
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
        guard let shoppingList = getShoppingListOf(storeName: self.storeName) else {
            fatalError("Cannot save new item to non existing Shopping List")
        }
        
        let groceryItem = GroceryItems(context: self.managedObjectContext)
        groceryItem.title = title
        groceryItem.identifier = UUID().uuidString
        groceryItem.storeName = shoppingList
        
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save new grocery item to core data. \(error.localizedDescription)")
        }
    }
    
    private func getShoppingListOf(storeName: String) -> ShoppingList? {
        let shoppingListFetch: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        shoppingListFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.title), storeName)
        
        do {
            let results = try managedObjectContext.fetch(shoppingListFetch)
            if results.count > 0 {
                return results.first!
            } else { return nil }
        } catch let error as NSError {
            fatalError("Failed to fetch shopping list. \(error.localizedDescription)")
        }
        
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
                try self.managedObjectContext.save()
            }
        } catch let error as NSError {
            fatalError("Failed to save updated item. \(error.localizedDescription)")
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
