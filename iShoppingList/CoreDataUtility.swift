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
            for result in results {
                moc.delete(result)
            }
            try moc.save()
        } catch let error as NSError {
            fatalError("Failed to delete item from warehouse. \(error.localizedDescription)")
        }
    }
}
