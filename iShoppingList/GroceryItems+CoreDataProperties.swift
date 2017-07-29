//
//  GroceryItems+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/29/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension GroceryItems {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItems> {
        return NSFetchRequest<GroceryItems>(entityName: "GroceryItems")
    }

    @NSManaged public var completionDate: NSDate?
    @NSManaged public var hasReminder: Bool
    @NSManaged public var identifier: String
    @NSManaged public var archived: Bool
    @NSManaged public var completed: Bool
    @NSManaged public var isRepeatedItem: Bool
    @NSManaged public var pendingDeletion: Bool
    @NSManaged public var reminderDate: NSDate?
    @NSManaged public var repetitionInterval: Double
    @NSManaged public var title: String
    @NSManaged public var synced: Bool
    @NSManaged public var lastCompletionDate: NSDate?
    @NSManaged public var remoteRecordID: String?
    @NSManaged public var storeName: ShoppingList?

}
