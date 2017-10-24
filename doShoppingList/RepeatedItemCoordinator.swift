//
//  RepeatedItemCoordinator.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation
import CoreData


class RepeatedItemsCoordinator {

    private var backgroundContext: NSManagedObjectContext!
    
    
    private static var sharedInstance: RepeatedItemsCoordinator!
    
    private init(moc: NSManagedObjectContext) {
        self.backgroundContext = moc
        RepeatedItemsCoordinator.sharedInstance = self
    }
    
    static func shared(backgroundContext: NSManagedObjectContext) -> RepeatedItemsCoordinator {
        switch (sharedInstance, backgroundContext) {
        case let (nil, moc):
            sharedInstance = RepeatedItemsCoordinator(moc: moc)
            return sharedInstance
        default:
            return sharedInstance
        }
    }

    // Check the warehouse for item to be delivered today 
    
    
    fileprivate func getStartAndEndOfDay() -> (startOfDay: NSDate, endOfDay: NSDate) {
        let calendar = Calendar.current
        let startofDay = calendar.startOfDay(for: Date())
        let endOfDay = startofDay + TimeIntervalConst.oneDay
        return (startofDay as NSDate, endOfDay as NSDate)
    }
    
    fileprivate func beforeTomorrowPredicate() -> NSPredicate {
        let (_, endOfDay) = getStartAndEndOfDay()
        let predicate = NSPredicate(format: "%K < %@ ",
                                    #keyPath(WarehouseGroceryItems.deliveryDate), endOfDay)
        return predicate
    }
    
    fileprivate func getDeliveryItemsForToday() -> [WarehouseGroceryItems] {
        let warehouseTodayFetch = NSFetchRequest<WarehouseGroceryItems>(entityName: "WarehouseGroceryItems")
        let sortOrder = NSSortDescriptor(key: "deliveryDate", ascending: true)
        let predicate = beforeTomorrowPredicate()
        warehouseTodayFetch.sortDescriptors = [sortOrder]
        warehouseTodayFetch.predicate = predicate
        
        let results: [WarehouseGroceryItems]
        do {
            results = try backgroundContext.fetch(warehouseTodayFetch)
            return results
        } catch let error as NSError {
            fatalError("Failed to retrieved warehouse today items from coreData. \(error.localizedDescription)")
        }
    }
    
    
    func transferTodayItemsToActiveGroceryItems() {
        let warehouseTodayItems = getDeliveryItemsForToday()
        print("Found \(warehouseTodayItems.count) items for delivery.")
        for warehouseItem in warehouseTodayItems {
            transferOneItemToActiveGroceryItems(item: warehouseItem)
        }
    }
    
    fileprivate func transferOneItemToActiveGroceryItems(item: WarehouseGroceryItems) {
        let groceryItem = GroceryItem(context: backgroundContext)
        let storeName = item.shoppingListTitle
        if let shoppingList = CoreDataUtil.getAShoppingListOf(storeName: storeName!, moc: backgroundContext) {
            shoppingList.addToItems(groceryItem)
            
            // set default first, then override as needed
            groceryItem.setDefaultValuesForLocalCreation()
            groceryItem.identifier = UUID().uuidString
            groceryItem.title = item.title
            groceryItem.localUpdate = NSDate()
            groceryItem.isRepeatedItem = item.isRepeatedItem
            groceryItem.repetitionInterval = item.repetitionInterval
            groceryItem.lastCompletionDate = item.protoCompletionDate
            groceryItem.price = item.price
        } else {
            fatalError("Not able to retrieve shoppingList for grocery item")
        }
        
        do {
            try backgroundContext.save()
        } catch let error as NSError {
            fatalError("Failed to save grocery item in coreData. \(error.localizedDescription)")
        }
        
        // Delete the proto to avoid confusion when new item completed too. 
        CoreDataUtil.deleteGroceryItem(identifier: item.protoIdentifier!, moc: backgroundContext)
        
        // Now delete the WarehouseItem
        backgroundContext.delete(item)
        do {
            try backgroundContext.save()
        } catch let error as NSError {
            fatalError("Failed to perform managed object save after deletion. \(error.localizedDescription)")
        }
    }
}

















