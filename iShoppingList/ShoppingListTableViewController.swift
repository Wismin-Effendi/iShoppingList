//
//  ShoppingListTableViewController.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListTableViewController: UITableViewController, UITextFieldDelegate {
    
    enum SegueIdentifier: String {
        case groceryItemsTableViewController = "GroceryItemsTableViewController"
    }
    
    
    var fetchedResultsProvider: FetchedResultsProvider<ShoppingList>!
    var dataSource: TableViewDataSource<ShoppingListCell, ShoppingList>!
    
    var coreDataStack: CoreDataStack!
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateShoppingLists()
    }

    private func populateShoppingLists() {
        
        self.fetchedResultsProvider = FetchedResultsProvider(managedObjectContext: self.managedObjectContext)
        self.dataSource = TableViewDataSource(cellIdentifier: "ShoppingListTableViewCell", tableView: self.tableView, fetchedResultsProvider: self.fetchedResultsProvider) { cell, model in
            cell.textLabel?.text = model.title
            cell.backgroundColor = UIColor.orange
            cell.accessoryType = .disclosureIndicator
            cell.coreDataIdentifier = model.identifier 
        }
        
        self.tableView.dataSource = self.dataSource
    }


    // Mark: TableViewDelegate 
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let addNewItemView = AddNewItemView(controller: self, placeHolderText: "Enter new Store name") { (title) in
            
            self.addNewShoppingList(title: title)
        }
                
        return addNewItemView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.zero)
    }
    
    private func addNewShoppingList(title: String) {
        
        let shoppingList = ShoppingList(context: managedObjectContext)
        shoppingList.title = title
        shoppingList.identifier = UUID().uuidString
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save new Shopping List to core data. \(error.localizedDescription)")
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == SegueIdentifier.groceryItemsTableViewController.rawValue,
            let groceryItemsTVC = segue.destination as? GroceryItemsTableViewController {
            
            groceryItemsTVC.coreDataStack = self.coreDataStack
            groceryItemsTVC.managedObjectContext = self.managedObjectContext
            groceryItemsTVC.storeNameTitle = (sender as? UITableViewCell)?.textLabel?.text
            groceryItemsTVC.storeIdentifier = (sender as? ShoppingListCell)?.coreDataIdentifier
        }
    }

}

extension ShoppingListTableViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}
