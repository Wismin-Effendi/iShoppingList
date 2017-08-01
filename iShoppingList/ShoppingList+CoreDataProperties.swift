//
//  ShoppingList+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/1/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension ShoppingList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingList> {
        return NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
    }

    @NSManaged public var identifier: String
    @NSManaged public var needsUpload: Bool
    @NSManaged public var title: String
    @NSManaged public var modificationDate: NSDate
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension ShoppingList {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: GroceryItems)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: GroceryItems)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
