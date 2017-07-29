//
//  CoreDataUtility.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


class CoreDataUtil {
    
    public static func getShoppingListOf(storeIdentifier: String, moc: NSManagedObjectContext) -> ShoppingList? {
        let shoppingListFetch: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        shoppingListFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.identifier), storeIdentifier)
        
        do {
            let results = try moc.fetch(shoppingListFetch)
            if results.count > 0 {
                return results.first!
            } else { return nil }
        } catch let error as NSError {
            fatalError("Failed to fetch shopping list. \(error.localizedDescription)")
        }
    }
    
    public static func getGroceryItem(identifier: String, moc: NSManagedObjectContext) -> GroceryItems? {
        let groceryItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        groceryItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.identifier), identifier)
        
        do {
            let results = try moc.fetch(groceryItemFetch)
            if results.count > 0 {
                return results.first!
            } else { return nil }
        } catch let error as NSError {
            fatalError("Failed to fetch grocery item by identifier. \(error.localizedDescription)")
        }
    }
    
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
    
    // MARK: For Testing 
    
    public static func getShoppingListOf(storeName: String, moc: NSManagedObjectContext) -> ShoppingList? {
        let shoppingListFetch: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        shoppingListFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.title), storeName)
        
        do {
            let results = try moc.fetch(shoppingListFetch)
            if results.count > 0 {
                return results.first!
            } else { return nil }
        } catch let error as NSError {
            fatalError("Failed to fetch shopping list. \(error.localizedDescription)")
        }
    }
    
    public static func deleteShoppingList(title: String, moc: NSManagedObjectContext) {
        let shoppingListFetch: NSFetchRequest<ShoppingList> = ShoppingList.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", #keyPath(ShoppingList.title), title)
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
        let groceryItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.title), title)
        groceryItemFetch.predicate = predicate
        do {
            let results = try moc.fetch(groceryItemFetch)
            for result in results {
                moc.delete(result)
                try moc.save()
            }
        } catch let error as NSError {
            fatalError("Failed to delete from groceryItems. \(error.localizedDescription)")
        }
    }

    public static func deleteAllGroceryItems(moc: NSManagedObjectContext) {
        let groceryItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        do {
            let results = try moc.fetch(groceryItemFetch)
            for result in results {
                moc.delete(result)
                try moc.save()
            }
        } catch let error as NSError {
            fatalError("Failed to delete from groceryItems. \(error.localizedDescription)")
        }
    }
    
    public static func createOneSampleShoppingList(title: String, moc: NSManagedObjectContext) {
        let item = ShoppingList(context: moc)
        item.title = title

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
        item.repetitionInterval = TimeIntervalConst.fourWeeks
        item.title = title
        item.deliveryDate = NSDate()
        item.shoppingListTitle = title
        
        do {
            try moc.save()
        } catch let error as NSError {
            fatalError("Failed to create sample Warehouse item. \(error.localizedDescription)")
        }
    }
    
    public static func createOneSampleGroceryItem(storeName: String, title: String, moc: NSManagedObjectContext) {
        let item = GroceryItems(context: moc)
        
        if let shoppingList = CoreDataUtil.getShoppingListOf(storeName: storeName, moc: moc) {
            shoppingList.addToItems(item)
            item.identifier = UUID().uuidString
            item.isRepeatedItem = true
            item.repetitionInterval = TimeIntervalConst.oneWeek
            item.title = title
            item.setDefaultValues()
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
    
    public static func getWarehouseItemsCount(title: String, moc: NSManagedObjectContext) -> Int {
        let currentItemFetch: NSFetchRequest<WarehouseGroceryItems> = WarehouseGroceryItems.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(WarehouseGroceryItems.title), title)
        
        do {
            let results = try moc.fetch(currentItemFetch)
            return results.count
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }

    public static func getGroceryItemsCount(title: String, moc: NSManagedObjectContext) -> Int {
        let currentItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        currentItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.title), title)
        
        do {
            let results = try moc.fetch(currentItemFetch)
            return results.count
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
    public static func getGroceryItemIdentifierFromTitle(title: String, moc: NSManagedObjectContext) -> String? {
        let groceryItemFetch: NSFetchRequest<GroceryItems> = GroceryItems.fetchRequest()
        groceryItemFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(GroceryItems.title), title)
        do {
            let results = try moc.fetch(groceryItemFetch)
            guard let first = results.first else { return nil }
            return first.identifier
        } catch let error as NSError {
            fatalError("Failed to retrieved item from coreData. \(error.localizedDescription)")
        }
    }
    
}
