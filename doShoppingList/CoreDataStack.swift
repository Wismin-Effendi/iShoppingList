//
//  CoreDataStack.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Core Data stack

/// We create singleton for coreDataStack so it's easy to access form anywhere. 
/// only the first call to shared(modelName: String)  will assign the model name.
/// any subsequence call to shared  will just return the already existing sharedInstance. 

class CoreDataStack {
    
    private let modelName: String
    
    
    private static var sharedInstance: CoreDataStack!
    
    private init(modelName: String) {
        self.modelName = modelName
        CoreDataStack.sharedInstance = self
    }
    
    static func shared(modelName: String) -> CoreDataStack {
        switch (sharedInstance, modelName) {
        case let (nil, modelName):
            sharedInstance = CoreDataStack(modelName: modelName)
            return sharedInstance
        default:
            return sharedInstance
        }
    }
    
    lazy var managedObjectContext: NSManagedObjectContext = {
       return self.storeContainer.viewContext
    }()
    
    
    private lazy var storeContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        guard managedObjectContext.hasChanges else { return }

        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
    }
    
    // MARK: - Expose performbackgroundTask and newBackgroundContext
    
    func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
        
        self.storeContainer.performBackgroundTask(block)
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return self.storeContainer.newBackgroundContext()
    }
    
}
