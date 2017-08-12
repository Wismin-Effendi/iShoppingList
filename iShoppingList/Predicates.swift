//
//  Predicates.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


class Predicates {
    
    static let NewShoppingList = NSPredicate(format: "%K == nil", #keyPath(ShoppingList.ckMetadata))
    static let UpdatedShoppingList = NSPredicate(format: "%K == YES", #keyPath(ShoppingList.needsUpload))
    static let DeletedShoppingList = NSPredicate(format: "%K == YES", #keyPath(ShoppingList.pendingDeletion))
    
    static let NewGroceryItem = NSPredicate(format: "%K == nil", #keyPath(GroceryItem.ckMetadata))
    static let UpdatedGroceryItem = NSPredicate(format: "%K == YES", #keyPath(GroceryItem.needsUpload))
    static let DeletedGroceryItem = NSPredicate(format: "%K == YES", #keyPath(GroceryItem.pendingDeletion))
    
}
