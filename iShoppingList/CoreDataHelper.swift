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
    
    func splitIntoComponents(recordName: String) -> (entityName: String, identifier: String) {
        guard let dotIndex = recordName.characters.index(of: ".") else {
            fatalError("ERROR - RecordID.recordName should contain entity prefix")
        }
        let entityName = recordName.substring(to: dotIndex)
        let indexAfterDot = recordName.index(dotIndex, offsetBy: 1)
        let identifier = recordName.substring(from: indexAfterDot)
        return (entityName: entityName, identifier: identifier)
    }
    
    func deleteManagedObject(using ckRecordID: CKRecordID, backgroundContext: NSManagedObjectContext) {
        let (entityName, identifier) = splitIntoComponents(recordName: ckRecordID.recordName)
        switch entityName {
        case EntityName.ShoppingList:
            CoreDataUtil.deleteShoppingList(identifier: identifier, moc: backgroundContext)
        case EntityName.GroceryItems:
            CoreDataUtil.deleteGroceryItem(identifier: identifier, moc: backgroundContext)
        default:
            fatalError("Unexpected entityName: \(entityName)")
        }
    }
    

    
}
