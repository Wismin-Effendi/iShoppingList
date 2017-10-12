//
//  ShoppingListTableViewController.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData
import os.log

class ShoppingListTableViewController: UITableViewController, UITextFieldDelegate {
    
    enum SegueIdentifier: String {
        case groceryItemsTableViewController = "GroceryItemsTableViewController"
    }
    
    static let notPendingDeletionPredicate = Predicates.ShoppingListNotPendingDeletion
    
    var fetchedResultsProvider: FetchedResultsProvider<ShoppingList>!
    var dataSource: TableViewDataSource<ShoppingListCell, ShoppingList>!
    
    var coreDataStack: CoreDataStack!
    var managedObjectContext: NSManagedObjectContext!
    
    var cloudKitHelper: CloudKitHelper!
    
    var appDelegate = AppDelegate.getAppDelegate()
    
    override func viewDidLoad()     {
        super.viewDidLoad()
        appDelegate.controller = self
      //  let nib = UINib(nibName: NibName.shoppingListCell.rawValue, bundle: nil)
      //  tableView.register(nib, forCellReuseIdentifier: CellIdentifier.shoppingList.rawValue)
        populateShoppingLists()
        setupRefreshControl()
        // show location for MySQL file
        print(NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).last! as String)
    }
    
    @objc func syncToCloudKit() {
        coreDataStack.saveContext()
        DispatchQueue.global(qos: .userInitiated).async {[weak self] in
            self?.cloudKitHelper.syncToCloudKit {
                DispatchQueue.main.async {
                    self?.populateShoppingLists()
                    self?.tableView.reloadData()
                }
            }
        }
        let delayTime = DispatchTime.now() + Constant.DelayBeforeRefetchAfterUpload
        DispatchQueue.global().asyncAfter(deadline: delayTime) {[weak self] in
            DispatchQueue.main.async {
                self?.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Sync to iCloud")
        refreshControl!.addTarget(self, action: #selector(ShoppingListTableViewController.syncToCloudKit), for: .valueChanged)
        tableView.addSubview(refreshControl!)
    }

    private func populateShoppingLists(predicate: NSPredicate = notPendingDeletionPredicate) {
        
        self.fetchedResultsProvider = FetchedResultsProvider(managedObjectContext: self.managedObjectContext,
                                                            additionalPredicate: predicate)
        self.dataSource = TableViewDataSource(cellIdentifier: CellIdentifier.shoppingList.rawValue, tableView: self.tableView, fetchedResultsProvider: self.fetchedResultsProvider) { cell, model in
            cell.textLabel?.text = model.title
            // cell.hasItems = model.items.count > 0
            cell.backgroundColor = UIColor.seaBuckthorn
            cell.accessoryType = .disclosureIndicator
            cell.coreDataIdentifier = model.identifier 
        }
        
        self.tableView.dataSource = self.dataSource
    }


    // Mark: TableViewDelegate 
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 91
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let addNewItemView = AddNewItemView(controller: self, itemType: AddItem.shoppingList.rawValue) { (title) in
            
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
        shoppingList.setDefaultValuesForLocalCreation()
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
            groceryItemsTVC.cloudKitHelper = self.cloudKitHelper
        }
    }

}

extension ShoppingListTableViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return  52
    }
}
