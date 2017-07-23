//
//  Extensions.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

extension ShoppingList: ManagedObjectType {
    
    static var entityName: String {
        return "ShoppingList"
    }
}

extension GroceryItems: ManagedObjectType {
    
    static var entityName: String {
        return "GroceryItems"
    }
}
 
