//
//  WarehouseGroceryItems+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension WarehouseGroceryItems {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WarehouseGroceryItems> {
        return NSFetchRequest<WarehouseGroceryItems>(entityName: "WarehouseGroceryItems")
    }

    @NSManaged public var identifier: String
    @NSManaged public var isRepeatedItem: Bool
    @NSManaged public var repetitionInterval: Double
    @NSManaged public var title: String
    @NSManaged public var deliveryDate: NSDate?
    @NSManaged public var shoppingListTitle: String

}
