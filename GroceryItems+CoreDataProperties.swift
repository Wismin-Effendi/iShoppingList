//
//  GroceryItems+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension GroceryItems {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItems> {
        return NSFetchRequest<GroceryItems>(entityName: "GroceryItems")
    }

    @NSManaged public var title: String?
    @NSManaged public var storeName: ShoppingList?

}
