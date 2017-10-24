//
//  CoreDataUtility.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import os.log

class CoreDataUtil {
        
    
    public static func deleteItemFromWarehouse(title: String, moc: NSManagedObjectContext) {
        let warehouseItemFetch: NSFetchRequest<WarehouseGroceryItems> = WarehouseGroceryItems.fetchRequest()
        warehouseItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(WarehouseGroceryItems.title), title)
        do {
            let results = try moc.fetch(warehouseItemFetch)
            print("Count: \(results.count)")
            for result in results {
                print("going to delete \(result.title) with id \(result.identifier)" )
                moc.delete(result)
                do {
                    guard moc.hasChanges else { continue }
                    try moc.save()
                } catch let error as NSError {
                    fatalError("Failed to perform managed object save after deletion. \(error.localizedDescription)")
                }
            }
        } catch let error as NSError {
            fatalError("Failed to delete item from warehouse. \(error.localizedDescription)")
        }
    }
    
    public static func getIDsShoppingListPendingDeletion(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "pendingDeletion == YES")
        let entity = ShoppingList()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsShoppingListNeedsUpload(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "needsUpload == YES")
        let entity = ShoppingList()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsGroceryItemsPendingDeletion(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "pendingDeletion == YES")
        let entity = GroceryItem()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsGroceryItemsNeedsUpload(moc: NSManagedObjectContext) -> [String] {
        let predicate = NSPredicate(format: "needsUpload == YES")
        let entity = GroceryItem()
        return getIDsOfEntities(entity: entity, predicate: predicate, moc: moc)
    }
    
    public static func getIDsOfEntities<E>(entity: E, predicate: NSPredicate, moc: NSManagedObjectContext) -> [String] where E: NSManagedObject, E: CloudKitConvertible {
        let entityFetch: NSFetchRequest<NSFetchRequestResult> = E.fetchRequest()
        entityFetch.predicate = predicate
        do {
            let results = (try moc.fetch(entityFetch)) as! [E]
            return results.map { $0.identifier }
        } catch let error as NSError {
            fatalError("Failed to retrieved all Identifier of GroceryItem for \(predicate) \(error.localizedDescription)")
        }
    }
    
    
    public static func getAShoppingListOf(storeIdentifier: String, moc: NSManagedObjectContext) -> ShoppingList? {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.identifier), storeIdentifier)
        return getShoppingListsOf(predicate: predicate, moc: moc).first
    }
    
    public static func doesShoppingListHasItems(storeIdentifier: String, moc: NSManagedObjectContext) -> Bool {
        guard let store = CoreDataUtil.getAShoppingListOf(storeIdentifier: storeIdentifier, moc: moc) else {
            return false
        }
        return store.items.count > 0
    }
    
    public static func getAShoppingListOf(storeName: String, moc: NSManagedObjectContext) -> ShoppingList? {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.title), storeName)
        return getShoppingListsOf(predicate: predicate, moc: moc).first
    }
    
    public static func getShoppingListsOf(predicate: NSPredicate, moc: NSManagedObjectContext) -> [ShoppingList] {
        let shoppingListFetch: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        shoppingListFetch.predicate = predicate
        
        do {
            let results = try moc.fetch(shoppingListFetch)
            if results.count > 0 {
                return results
            } else { return [] }
        } catch let error as NSError {
            fatalError("Failed to fetch shopping lists. \(error.localizedDescription)")
        }
    }
    
    
    public static func getGroceryItem(identifier: String, moc: NSManagedObjectContext) -> GroceryItem? {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.identifier), identifier)
        return getGroceryItems(predicate: predicate, moc: moc).first
    }
    
    public static func getGroceryItems(predicate: NSPredicate, moc: NSManagedObjectContext) -> [GroceryItem] {
        let groceryItemFetch: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        groceryItemFetch.predicate = predicate
        
        do {
            let results = try moc.fetch(groceryItemFetch)
            if results.count > 0 {
                return results
            } else { return [] }
        } catch let error as NSError {
            fatalError("Failed to fetch grocery items by identifier. \(error.localizedDescription)")
        }
    }
    
    public static func deleteShoppingList(title: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.title), title)
        deleteShoppingList(predicate: predicate, moc: moc)
    }

    public static func deleteShoppingList(identifier: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.identifier), identifier)
        deleteShoppingList(predicate: predicate, moc: moc)
    }
  
    public static func deleteShoppingList(predicate: NSPredicate, moc: NSManagedObjectContext) {
        let shoppingListFetch: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        shoppingListFetch.predicate = predicate
        do {
            let results = try moc.fetch(shoppingListFetch)
            for result in results {
                moc.delete(result)
                try moc.save()
            }
        } catch let error as NSError {
            fatalError("Failed to delete from shoppingList. \(error.localizedDescription)")
        }
    }


    
    public static func deleteGroceryItem(title: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.title), title)
        deleteGroceryItem(predicate: predicate, moc: moc)
    }
    
    public static func deleteGroceryItem(identifier: String, moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.identifier), identifier)
        deleteGroceryItem(predicate: predicate, moc: moc)
    }

    public static func deleteAllGroceryItems(moc: NSManagedObjectContext) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        deleteGroceryItem(predicate: predicate, moc: moc)
    }
    
    public static func deleteGroceryItem(predicate: NSPredicate, moc: NSManagedObjectContext) {
        let groceryItemFetch: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        groceryItemFetch.predicate = predicate
        do {
            let results = try moc.fetch(groceryItemFetch)
            for result in results {
                if let shoppingList = result.storeName {
                    shoppingList.removeFromItems(result)
                }
                moc.delete(result)
                try moc.save()
            }
        } catch let error as NSError {
            fatalError("Failed to delete from groceryItem. \(error.localizedDescription)")
        }
    }
    
    public static func updateShoppingListCKMetadata(from cloudKitRecords: [CKRecord], managedObjectContext: NSManagedObjectContext) {
        for ckRecord in cloudKitRecords {
            let identifier: String = ckRecord[ckShoppingList.identifier] as! String
            if let shoppingList = getAShoppingListOf(storeIdentifier: identifier, moc: managedObjectContext) {
                shoppingList.updateCKMetadata(from: ckRecord)
            } else {
                let title = ckRecord[ckShoppingList.title] as! String
                fatalError("Can't find record to update metadata for \(title)")
            }
        }
    }
    
    public static func updateGroceryItemCKMetadata(from cloudKitRecords: [CKRecord], managedObjectContext: NSManagedObjectContext) {
        for ckRecord in cloudKitRecords {
            let identifier: String = ckRecord[ckGroceryItem.identifier] as! String
            if let groceryItem = getGroceryItem(identifier: identifier, moc: managedObjectContext) {
                groceryItem.updateCKMetadata(from: ckRecord)
            } else {
                let title = ckRecord[ckGroceryItem.title] as! String
                fatalError("Can't find record to update metadata for \(title)")
            }
        }
    }
    
    public static func batchDeleteShoppingListPendingDeletion(managedObjectContext: NSManagedObjectContext) {
        let shoppingListFetch: NSFetchRequest<NSFetchRequestResult> = ShoppingList.fetchRequest()
        shoppingListFetch.predicate = Predicates.DeletedShoppingList
        batchDeleteManagedObject(fetchRequest: shoppingListFetch, managedObjectContext: managedObjectContext)
    }
    
    public static func batchDeleteGroceryItemPendingDeletion(managedObjectContext: NSManagedObjectContext) {
        let groceryItemFetch: NSFetchRequest<NSFetchRequestResult> = GroceryItem.fetchRequest()
        groceryItemFetch.predicate = Predicates.DeletedGroceryItem
        batchDeleteManagedObject(fetchRequest: groceryItemFetch, managedObjectContext: managedObjectContext)
    }
    
    public static func batchDeleteManagedObject(fetchRequest: NSFetchRequest<NSFetchRequestResult>, managedObjectContext: NSManagedObjectContext) {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeStatusOnly
        try! managedObjectContext.execute(batchDeleteRequest)
    }
    
    public static func createOneSampleShoppingList(title: String, moc: NSManagedObjectContext) {
        let item = ShoppingList(context: moc)
        item.title = title
        item.identifier = UUID().uuidString
        do {
            try moc.save()
        } catch let error as NSError {
            fatalError("Failed to create sample ShoppingList item. \(error.localizedDescription)")
        }
    }
    
    public static func createOneSampleItemInWarehouse(title: String, moc: NSManagedObjectContext) {
        let item = WarehouseGroceryItems(context: moc)
        item.identifier = UUID().uuidString
        item.isRepeatedItem = true
        item.repetitionInterval = TimeIntervalConst.fourDays
        item.title = title
        item.deliveryDate = NSDate()
        item.shoppingListTitle = title
        
        do {
            try moc.save()
        } catch let error as NSError {
            fatalError("Failed to create sample Warehouse item. \(error.localizedDescription)")
        }
    }
    
    public static func createOneSampleGroceryItem(storeName: String, title: String, repetitionInterval: TimeInterval = TimeIntervalConst.twoWeeks, moc: NSManagedObjectContext) {
        let item = GroceryItem(context: moc)
        
        if let shoppingList = CoreDataUtil.getAShoppingListOf(storeName: storeName, moc: moc) {
            shoppingList.addToItems(item)
            item.setDefaultValuesForLocalCreation()
            item.identifier = UUID().uuidString
            item.isRepeatedItem = true
            item.repetitionInterval = repetitionInterval
            item.completionDate = NSDate()
            item.title = title
            
        }
        do {
            try moc.save()
        } catch let error as NSError {
            fatalError("Failed to create sample Warehouse item. \(error.localizedDescription)")
        }
    }

    public static func getWarehouseItem(title: String, moc: NSManagedObjectContext) -> WarehouseGroceryItems? {
        let currentItemFetch: NSFetchRequest<WarehouseGroceryItems> = WarehouseGroceryItems.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(WarehouseGroceryItems.title), title)
        
        do {
            let results = try moc.fetch(currentItemFetch)
            return results.first
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    

    /// MARK:  Get records count
    public static func getWarehouseItemsCount(title: String, moc: NSManagedObjectContext) -> Int {
        let keyPathExp = NSExpression(forKeyPath: #keyPath(WarehouseGroceryItems.title))
        let predicate = NSPredicate(format: "%K == %@", #keyPath(WarehouseGroceryItems.title), title)
        return getEntityItemsCount(keyPathExp: keyPathExp, predicate: predicate, type: WarehouseGroceryItems(), moc: moc)
    }
    
    public static func getGroceryItemsCount(title: String, moc: NSManagedObjectContext) -> Int {
        let keyPathExp = NSExpression(forKeyPath: #keyPath(GroceryItem.title))
        let predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.title), title)
        let type = GroceryItem()
        return getEntityItemsCount(keyPathExp: keyPathExp, predicate: predicate, type: type, moc: moc)
    }

    // A proper way to count given that we don't fetch items to memory just to count them.
    public static func getEntityItemsCount<T: NSManagedObject>(keyPathExp: NSExpression, predicate: NSPredicate,
                                           type: T, moc: NSManagedObjectContext) -> Int {
        
        let expression = NSExpression(forFunction: "count:", arguments: [keyPathExp])
        
        let countDesc = NSExpressionDescription()
        countDesc.expression = expression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        
        let currentItemFetch: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
        currentItemFetch.predicate = predicate
        currentItemFetch.returnsObjectsAsFaults = false
        currentItemFetch.propertiesToFetch = [countDesc]
        currentItemFetch.resultType = .countResultType
        
        do {
            let countResults = try moc.fetch(currentItemFetch)
            return countResults.first as! Int
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
    
    public static func getGroceryItemIdentifierFromTitle(title: String, moc: NSManagedObjectContext) -> String? {
        let groceryItemFetch: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        groceryItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItem.title), title)
        do {
            let results = try moc.fetch(groceryItemFetch)
            guard let first = results.first else { return nil }
            return first.identifier
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
    
    public static func createNewShoppingListRecord(from cloudKitRecord: CKRecord, moc: NSManagedObjectContext,
                                                   completion: (NSError?) -> ()) {
        _ = ShoppingList(using: cloudKitRecord, context: moc)
        do {
            try moc.save()
        } catch let error as NSError {
            os_log("Failed to create shopping list record. %@", error.localizedDescription)
            completion(error)
        }
        completion(nil)
    }
    
    public static func updateCoreDataShoppingListRecord(_ shoppingList: ShoppingList, using cloudKitRecord: CKRecord,
                                                        moc: NSManagedObjectContext, completion: (NSError?) -> ()) {
        shoppingList.update(using: cloudKitRecord)
        do {
            try moc.save()
        } catch let error as NSError {
            os_log("Failed to update shopping list record. %@", error.localizedDescription)
            completion(error)
        }
        completion(nil)
    }


    public static func updateCoreDataGroceryItemRecord(_ groceryItem: GroceryItem, using cloudKitRecord: CKRecord,
                                                         moc: NSManagedObjectContext, completion: (NSError?) -> ()) {
        groceryItem.update(using: cloudKitRecord)
        do {
            try moc.save()
        } catch let error as NSError {
            os_log("Failed to update grocery item record. %@", error.localizedDescription)
            completion(error)
        }
        completion(nil)
    }
    
    public static func getPreviousServerChangeToken(moc: NSManagedObjectContext) -> CKServerChangeToken?  {
        let changeTokenFetch: NSFetchRequest<ChangeToken> = ChangeToken.fetchRequest()
        changeTokenFetch.fetchLimit = 1
        do {
            let results = try moc.fetch(changeTokenFetch)
            return results.first?.previousServerChangeToken as? CKServerChangeToken
        } catch let error as NSError {
            fatalError("Failed to retrieve from ChangeToken. \(error.localizedDescription)")
        }
    }
    
    public static func deletePreviousServerChangeToken(moc: NSManagedObjectContext) {
        let changeTokenFetch: NSFetchRequest<ChangeToken> = ChangeToken.fetchRequest()
        changeTokenFetch.fetchLimit = 1
        do {
            let results = try moc.fetch(changeTokenFetch)
            if results.count == 0 { return }
            else if results.count == 1 {
                let changeToken = results.first!
                moc.delete(changeToken)
                try moc.save()
            } else {
                fatalError("ChangeToken should only has one entry")
            }
        } catch let error as NSError {
            fatalError("Failed to retrieve from ChangeToken. \(error.localizedDescription)")
        }
    }
    
    public static func setPreviousServerChangeToken(previousServerChangeToken: CKServerChangeToken, moc: NSManagedObjectContext) {
        
        let changeTokenFetch: NSFetchRequest<ChangeToken> = ChangeToken.fetchRequest()
        changeTokenFetch.fetchLimit = 1
        
        let changeToken: ChangeToken
        do {
            let results = try moc.fetch(changeTokenFetch)
            if results.count > 0 {
                changeToken = results.first!
                changeToken.previousServerChangeToken = previousServerChangeToken
            } else {
                changeToken = ChangeToken(context: moc)
                changeToken.previousServerChangeToken = previousServerChangeToken
            }
            try moc.save()
        } catch let error as NSError {
            fatalError("Failed to create from ChangeToken. \(error.localizedDescription)")
        }
    }
}
