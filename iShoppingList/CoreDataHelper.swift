//
//  CoreDataHelper.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import os.log
import CoreData
import CloudKit


class CoreDataHelper {
    
    
    static let sharedInstance = CoreDataHelper()
    
    private init() {}
    
    func insertOrUpdateManagedObject(using ckRecord: CKRecord, backgroundContext: NSManagedObjectContext) {
        switch ckRecord.recordType {
        case EntityName.ShoppingList:
            if let storeIdentifier = ckRecord[ckShoppingList.identifier] as? String,
                let shoppingList = CoreDataUtil.getShoppingListOf(storeIdentifier: storeIdentifier, moc: backgroundContext) {
                shoppingList.update(using: ckRecord)
            } else {
                let _ = ShoppingList.init(using: ckRecord, context: backgroundContext)
            }
        case EntityName.GroceryItems:
            if let identifier = ckRecord[ckGroceryItem.identifier] as? String,
                let groceryItem = CoreDataUtil.getGroceryItem(identifier: identifier, moc: backgroundContext) {
                groceryItem.update(using: ckRecord)
            } else{
                let _ = GroceryItems.init(using: ckRecord, context: backgroundContext)
            }
        default: fatalError("We got unexpected type: \(ckRecord.recordType)")
        }
    }
    
    func deleteManagedObject(using ckRecordID: CKRecordID) {
        
    }
}
