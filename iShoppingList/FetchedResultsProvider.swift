//
//  FetchedResultsProvider.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import os.log 

protocol FetchedResultsProviderDelegate: class {
    var tableView: UITableView! { get }
    func fetchedResultsProviderDidInsert(indexPath: IndexPath)
    func fetchedResultsProviderDidDelete(indexPath: IndexPath)
    func fetchedResultsProviderDidUpdate(indexPath: IndexPath)
    func fetchedResultsProviderDidMove(from: IndexPath, to: IndexPath)
    func fetchedResultsProviderSectionDidInsert(indexSet: IndexSet)
    func fetchedResultsProviderSectionDidDelete(indexSet: IndexSet)
}

class FetchedResultsProvider<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate
where T: ManagedObjectType & CloudKitConvertible {
    
    weak var delegate: FetchedResultsProviderDelegate!
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<T>! = nil
    
    var sectionChanges: [[UInt: Int]]!
    var itemChanges: [[UInt: [IndexPath]]]!
    
    init(managedObjectContext: NSManagedObjectContext, additionalPredicate: NSPredicate? = nil) {

        self.managedObjectContext = managedObjectContext
    
        super.init()
        self.setupFetchResultsController(additionalPredicate: additionalPredicate)
        self.fetchedResultsController.delegate = self

        do {
            try self.fetchedResultsController.performFetch()
        } catch let error as NSError{
            fatalError("FetchedResults Controller failed to perform fetch with error: \(error.localizedDescription)")
        }
    }
    
    private func setupFetchResultsController(additionalPredicate: NSPredicate? = nil) {
        
        let request = NSFetchRequest<T>(entityName: T.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        
        if let predicate = additionalPredicate {
            request.predicate = predicate
        }
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    
    
    func delete(model: T) {
        var shoppingList: ShoppingList!
        var groceryItem: GroceryItem!
        
        switch T.entityName {
        case EntityName.ShoppingList:
            shoppingList = CoreDataUtil.getAShoppingListOf(storeIdentifier: model.identifier, moc: self.managedObjectContext)
            shoppingList.needsUpload ?  self.managedObjectContext.delete(shoppingList) : (shoppingList.setForLocalDeletion())
        case EntityName.GroceryItem:
            groceryItem = CoreDataUtil.getGroceryItem(identifier: model.identifier, moc: self.managedObjectContext)
            groceryItem.needsUpload ? self.managedObjectContext.delete(groceryItem) : (groceryItem.setForLocalDeletion())
        default: break
        }
        //
        guard self.managedObjectContext.hasChanges else { return }
            os_log("We detected the pendingDeletion update..")
        DispatchQueue.main.async {
            try! self.managedObjectContext.save()
        }
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        guard let sections = self.fetchedResultsController.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func objectAt(indexPath: IndexPath) -> T {
        return self.fetchedResultsController.object(at: indexPath)
    }
    
    func numberOfSections() -> Int {
        guard let sections = self.fetchedResultsController.sections else {
            return 0
        }
        return sections.count
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sectionChanges = [[UInt:Int]]()
        itemChanges = [[UInt: [IndexPath]]]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        var change = [UInt: Int]()
        change[type.rawValue] = sectionIndex
        sectionChanges.append(change)
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        var change = [UInt:[IndexPath]]()
        
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                change[type.rawValue] = [indexPath]
            }
        case .delete:
            if let indexPath = indexPath {
                change[type.rawValue] = [indexPath]
            }
        case .update:
            if let indexPath = indexPath {
                change[type.rawValue] = [indexPath]
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                change[type.rawValue] = [indexPath, newIndexPath]
            }
        }
        itemChanges.append(change)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if #available(iOS 11.0, *) {
            self.delegate.tableView.performBatchUpdates({ () -> Void in
                for change in self.sectionChanges {
                    change.forEach({ (key, value) in
                        let type = NSFetchedResultsChangeType.init(rawValue: key)!
                        switch type {
                        case .insert:
                            self.delegate.fetchedResultsProviderSectionDidInsert(indexSet: IndexSet(integer: value))
                        case .delete:
                            self.delegate.fetchedResultsProviderSectionDidDelete(indexSet: IndexSet(integer: value))
                        default:
                            break
                        }
                    })
                }
                
                for change in self.itemChanges {
                    change.forEach({ (key, value) in
                        let type = NSFetchedResultsChangeType.init(rawValue: key)!
                        switch type {
                        case .insert:
                            self.delegate.fetchedResultsProviderDidInsert(indexPath: value[0])
                        case .delete:
                            self.delegate.fetchedResultsProviderDidDelete(indexPath: value[0])
                        case .update:
                            self.delegate.fetchedResultsProviderDidUpdate(indexPath: value[0])
                        case .move:
                            self.delegate.fetchedResultsProviderDidMove(from: value[0], to: value[1])
                        }
                    })
                }
            }) { (_ finished: Bool) in
                self.sectionChanges = nil
                self.itemChanges = nil
            }
        } else {
            // Fallback on earlier versions
        }
    }
}





