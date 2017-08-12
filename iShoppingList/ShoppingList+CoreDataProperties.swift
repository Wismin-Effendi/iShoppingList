//
//  ShoppingList+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension ShoppingList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingList> {
        return NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
    }

    @NSManaged public var ckMetadata: NSObject?
    @NSManaged public var identifier: String
    @NSManaged public var localUpdate: NSDate?
    @NSManaged public var needsUpload: Bool
    @NSManaged public var pendingDeletion: Bool
    @NSManaged public var title: String
    @NSManaged public var items: NSSet

}

// MARK: Generated accessors for items
extension ShoppingList {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: GroceryItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: GroceryItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
