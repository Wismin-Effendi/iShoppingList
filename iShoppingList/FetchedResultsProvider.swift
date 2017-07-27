//
//  FetchedResultsProvider.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

protocol FetchedResultsProviderDelegate: class {
    func fetchedResultsProviderDidInsert(indexPath: IndexPath)
    func fetchedResultsProviderDidDelete(indexPath: IndexPath)
}

class FetchedResultsProvider<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate
where T: ManagedObjectType {
    
    weak var delegate: FetchedResultsProviderDelegate!
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<T>! = nil 
    
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
        self.managedObjectContext.delete(model)
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to perform managed object save after deletion. \(error.localizedDescription)")
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == .insert, let newIndexPath = newIndexPath {
            self.delegate.fetchedResultsProviderDidInsert(indexPath: newIndexPath)
        } else if type == .delete, let indexPath = indexPath {
            self.delegate.fetchedResultsProviderDidDelete(indexPath: indexPath)
        }
    }
}





