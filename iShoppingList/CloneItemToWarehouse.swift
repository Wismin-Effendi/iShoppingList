//
//  CloneItemToWarehouse.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


class CloneItemToWarehouse {
    
    var managedObjectContext: NSManagedObjectContext!
    
    var warehouseGroceryItem: WarehouseGroceryItems
    var prototype: GroceryItems
    
    init(prototype: GroceryItems) {
        self.prototype = prototype
        warehouseGroceryItem = WarehouseGroceryItems(context: managedObjectContext)
        createCloneFromPrototype()
    }
    
    fileprivate func createCloneFromPrototype() {
        // store shoppingList name to be use during delivery day
        warehouseGroceryItem.shoppingListTitle = prototype.storeName.title
        // set deliveryDate to be checked periodically for time to deliver (i.e. move to active GroceryItems)
        warehouseGroceryItem.deliveryDate = calculateDeliveryDate() as NSDate
        // copy mandatory fields
        warehouseGroceryItem.title = prototype.title
        warehouseGroceryItem.isRepeatedItem = prototype.isRepeatedItem
        warehouseGroceryItem.repetitionInterval = prototype.repetitionInterval
        // initialize the rest
        warehouseGroceryItem.identifier = UUID().uuidString
        
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError {
            fatalError("Failed to save new warehouse grocery item to core data." + "\(error.localizedDescription)")
        }
    }
    
    
    fileprivate func calculateDeliveryDate() -> Date {
        let repetitionInterval = prototype.repetitionInterval
        let lastCompletionDate = prototype.completionDate! as Date
        let deliveryInterval = deliveryIntervalFrom(repetitionInterval: repetitionInterval)
        return lastCompletionDate + deliveryInterval
    }
    
    fileprivate func deliveryIntervalFrom(repetitionInterval: TimeInterval) -> TimeInterval {
        // if > 2 weeks, then 3 days warning ahead
        // if 1 weeks, then 2 days warning ahead
        // if > 1 days, then 1 days ahead
        // if >= 1 months, then 4 days ahead
        
        typealias TIC = TimeIntervalConst
        
        switch repetitionInterval {
        case TIC.oneWeek...TIC.fourWeeks:
            return repetitionInterval - TIC.threeDays
        case TIC.oneWeek:
            return repetitionInterval - TIC.twoDays
        case TIC.oneDay:
            return repetitionInterval - TIC.oneDay
        case TIC.oneMonth...TIC.twentySixMonths:
            return repetitionInterval - TIC.fourDays
        default:
            return repetitionInterval - TIC.oneDay
        }
    }
    
}
