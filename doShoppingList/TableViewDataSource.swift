//
//  TableViewDataSource.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import UIKit
import CoreData

class TableViewDataSource<Cell: UITableViewCell, Model: NSManagedObject> : NSObject,
UITableViewDataSource, FetchedResultsProviderDelegate where Model: ManagedObjectType & CloudKitConvertible {

    var cellIdentifier: String!
    var fetchedResultsProvider: FetchedResultsProvider<Model>!
    var configureCell: (Cell, Model) -> ()
    var tableView: UITableView!
    
    
    init(cellIdentifier: String, tableView: UITableView, fetchedResultsProvider: FetchedResultsProvider<Model>,
         configureCell: @escaping (Cell, Model) -> ()) {
        
        self.cellIdentifier = cellIdentifier
        self.fetchedResultsProvider = fetchedResultsProvider
        self.configureCell = configureCell
        self.tableView = tableView
        
        super.init()
        self.fetchedResultsProvider.delegate = self
    }
    
    func fetchedResultsProviderDidInsert(indexPath: IndexPath) {
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func fetchedResultsProviderDidDelete(indexPath: IndexPath) {
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func fetchedResultsProviderDidUpdate(indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func fetchedResultsProviderDidMove(from: IndexPath, to: IndexPath) {
        self.tableView.moveRow(at: from, to: to)
    }
    
    func fetchedResultsProviderSectionDidInsert(indexSet: IndexSet) {
        self.tableView.insertSections(indexSet, with: .automatic)
    }
    
    func fetchedResultsProviderSectionDidDelete(indexSet: IndexSet) {
        self.tableView.deleteSections(indexSet, with: .automatic)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsProvider.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.fetchedResultsProvider.numberOfRowsInSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        let model = self.fetchedResultsProvider.objectAt(indexPath: indexPath)

        // prevent delete action on ShoppingList unless the GroceryItem is empty
        if let shoppingList = model as? ShoppingList,
            shoppingList.items.count > 1
        {
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let model = self.fetchedResultsProvider.objectAt(indexPath: indexPath)
            self.fetchedResultsProvider.delete(model: model)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath) as! Cell
        let model: Model = self.fetchedResultsProvider.objectAt(indexPath: indexPath)
        
        cell.selectionStyle = .none
        self.configureCell(cell, model)
        
        return cell
    }

}
