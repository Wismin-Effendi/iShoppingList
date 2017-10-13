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
    static let UpdatedShoppingList = NSPredicate(format: "%K == YES AND %K != nil",
                                                 #keyPath(ShoppingList.needsUpload),
                                                 #keyPath(ShoppingList.ckMetadata))
    static let DeletedShoppingList = NSPredicate(format: "%K == YES", #keyPath(ShoppingList.pendingDeletion))
    
    static let NewGroceryItem = NSPredicate(format: "%K == nil", #keyPath(GroceryItem.ckMetadata))
    static let UpdatedGroceryItem = NSPredicate(format: "%K == YES AND %K != nil",
                                                #keyPath(GroceryItem.needsUpload),
                                                #keyPath(GroceryItem.ckMetadata))
    static let DeletedGroceryItem = NSPredicate(format: "%K == YES", #keyPath(GroceryItem.pendingDeletion))
 
    static let ShoppingListNotPendingDeletion = NSPredicate(format: "%K == NO", #keyPath(ShoppingList.pendingDeletion))
}
