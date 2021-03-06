//
//  GroceryItem+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 10/11/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//
//

import Foundation
import CoreData


extension GroceryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItem> {
        return NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
    }

    @NSManaged public var archived: Bool
    @NSManaged public var ckMetadata: NSObject?
    @NSManaged public var completed: Bool
    @NSManaged public var completionDate: NSDate?
    @NSManaged public var hasReminder: Bool
    @NSManaged public var identifier: String
    @NSManaged public var isRepeatedItem: Bool
    @NSManaged public var lastCompletionDate: NSDate?
    @NSManaged public var localUpdate: NSDate?
    @NSManaged public var needsUpload: Bool
    @NSManaged public var pendingDeletion: Bool
    @NSManaged public var reminderDate: NSDate?
    @NSManaged public var repetitionInterval: Double
    @NSManaged public var title: String
    @NSManaged public var price: Double
    @NSManaged public var storeName: ShoppingList?

}
