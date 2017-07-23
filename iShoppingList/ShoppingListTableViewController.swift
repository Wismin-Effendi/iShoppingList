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
    var dataSource: TableViewDataSource<UITableViewCell, ShoppingList>!
    
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
        }
        
        self.tableView.dataSource = self.dataSource
    }


    // Mark: TableViewDelegate 
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let addNewItemView = AddNewItemView(controller: self, placeHolderText: "Enter new Store name") { (title) in
            
            self.addNewShoppingList(title: title)
        }
                
        return addNewItemView
    }
    
    
    private func addNewShoppingList(title: String) {
        
        let shoppingList = ShoppingList(context: managedObjectContext)
        shoppingList.title = title
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save new Shopping List to core data. \(error.localizedDescription)")
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == SegueIdentifier.groceryItemsTableViewController.rawValue,
            let groceryItemsTVC = segue.destination as? GroceryItemsTableViewController {
            
            groceryItemsTVC.managedObjectContext = self.managedObjectContext
            groceryItemsTVC.storeName = (sender as? UITableViewCell)?.textLabel?.text
        }
    }

}
