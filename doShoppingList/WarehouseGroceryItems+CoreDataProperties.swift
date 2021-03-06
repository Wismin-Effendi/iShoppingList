//
//  WarehouseGroceryItems+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 10/11/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//
//

import Foundation
import CoreData


extension WarehouseGroceryItems {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WarehouseGroceryItems> {
        return NSFetchRequest<WarehouseGroceryItems>(entityName: "WarehouseGroceryItems")
    }

    @NSManaged public var deliveryDate: NSDate
    @NSManaged public var identifier: String
    @NSManaged public var isRepeatedItem: Bool
    @NSManaged public var localUpdate: NSDate?
    @NSManaged public var needsUpload: Bool
    @NSManaged public var protoCompletionDate: NSDate?
    @NSManaged public var protoIdentifier: String?
    @NSManaged public var repetitionInterval: Double
    @NSManaged public var shoppingListTitle: String?
    @NSManaged public var title: String
    @NSManaged public var price: Double

}
