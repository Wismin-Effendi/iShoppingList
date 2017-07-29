//
//  WarehouseGroceryItems+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

@objc(WarehouseGroceryItems)
public class WarehouseGroceryItems: NSManagedObject {
    
    public override var description: String {
        return "Store: \(shoppingListTitle)  Title: \(title)  deliveryDate: \((deliveryDate! as Date))"
    }
}
