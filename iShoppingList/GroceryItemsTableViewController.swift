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
    var dataSource: TableViewDataSource<UITableViewCell, GroceryItems>!
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
                                              fetchedResultsProvider: self.fetchedResultsProvider) { cell,model in
         
            cell.textLabel?.text = model.title
            cell.backgroundColor = UIColor.green
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

    
    private func addNewGroceryItem(title: String) {
        guard let shoppingList = getShoppingListOf(storeName: self.storeName) else {
            fatalError("Cannot save new item to non existing Shopping List")
        }
        
        let groceryItem = GroceryItems(context: self.managedObjectContext)
        groceryItem.title = title
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
