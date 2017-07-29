//
//  RepeatedItemCoordinator.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


// Note: This should not run on main queue, we should make sure we run on other thread. Need to use performBackgroundTaks of iOS 10 CoreData stack.

// Idea, maybe we don't need to keep checking periodic, too much waste,
// Better to just create a spare in another Entity with same schema + Date when to move to active Items list
// As an item is completed, we check if it's a repeated item, if so we clone to new Entity with Execution date field. Everytime app start, we check the warehause for  'clone delivery of the day'  if not empty, we move them to active list. No other processing required. (Ans: Implemented)
// This way we distribute the processing load and should have not impact on performance. 

// also when we update an item to become repeated, we need to process that item and clone to new Entity (warehouse)
// 
// Things no clear yet. What if an item has been cloned (either in warehouse or active items) but then we update and change to no-repeat? (Ans: Implemented)
// -- I think we need to clean up the warehouse of that item, but if item already in active items list, we should leave them alone. 



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
    
    fileprivate func todayPredicate() -> NSPredicate {
        let (startOfDay, endOfDay) = getStartAndEndOfDay()
        let predicate = NSPredicate(format: "%K >= %@ AND %K < %@ ",
                                    #keyPath(WarehouseGroceryItems.deliveryDate), startOfDay,
                                    #keyPath(WarehouseGroceryItems.deliveryDate), endOfDay)
        return predicate
    }
    
    fileprivate func getDeliveryItemsForToday() -> [WarehouseGroceryItems] {
        let warehouseTodayFetch = NSFetchRequest<WarehouseGroceryItems>(entityName: "WarehouseGroceryItems")
        let sortOrder = NSSortDescriptor(key: "deliveryDate", ascending: true)
        let predicate = todayPredicate()
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
        for warehouseItem in warehouseTodayItems {
            transferOneItemToActiveGroceryItems(item: warehouseItem)
        }
    }
    
    fileprivate func transferOneItemToActiveGroceryItems(item: WarehouseGroceryItems) {
        let groceryItem = GroceryItems(context: backgroundContext)
        let storeName = item.shoppingListTitle
        if let shoppingList = CoreDataUtil.getShoppingListOf(storeName: storeName, moc: backgroundContext) {
            shoppingList.addToItems(groceryItem)
            groceryItem.identifier = UUID().uuidString
            groceryItem.title = item.title
            groceryItem.isRepeatedItem = item.isRepeatedItem
            groceryItem.repetitionInterval = item.repetitionInterval
            groceryItem.setDefaultValues()
        } else {
            fatalError("Not able to retrieve shoppingList for grocery item")
        }
       
        do {
            try backgroundContext.save()
        } catch let error as NSError {
            fatalError("Failed to save grocery item in coreData. \(error.localizedDescription)")
        }
        
        backgroundContext.delete(item)
        do {
            try backgroundContext.save()
        } catch let error as NSError {
            fatalError("Failed to perform managed object save after deletion. \(error.localizedDescription)")
        }
    }
}

















