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
    
    func insertOrUpdateManagedObject(using ckRecord: CKRecord, managedObjectContext: NSManagedObjectContext) {
        switch ckRecord.recordType {
        case EntityName.ShoppingList:
            if let storeIdentifier = ckRecord[ckShoppingList.identifier] as? String,
                let shoppingList = CoreDataUtil.getAShoppingListOf(storeIdentifier: storeIdentifier, moc: managedObjectContext) {
                shoppingList.update(using: ckRecord)
            } else {
                let _ = ShoppingList.init(using: ckRecord, context: managedObjectContext)
            }
        case EntityName.GroceryItem:
            if let identifier = ckRecord[ckGroceryItem.identifier] as? String,
                let groceryItem = CoreDataUtil.getGroceryItem(identifier: identifier, moc: managedObjectContext) {
                    print("yes, we found the record...")
                    groceryItem.update(using: ckRecord)
            } else{
                let _ = GroceryItem.init(using: ckRecord, context: managedObjectContext)
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
    
    func deleteManagedObject(using ckRecordID: CKRecordID, managedObjectContext: NSManagedObjectContext) {
        let (entityName, identifier) = splitIntoComponents(recordName: ckRecordID.recordName)
        switch entityName {
        case EntityName.ShoppingList:
            CoreDataUtil.deleteShoppingList(identifier: identifier, moc: managedObjectContext)
        case EntityName.GroceryItem:
            CoreDataUtil.deleteGroceryItem(identifier: identifier, moc: managedObjectContext)
        default:
            fatalError("Unexpected entityName: \(entityName)")
        }
    }
    
    func ckReferenceOf(shoppingList: ShoppingList) -> CKReference {
        let recordID = shoppingList.getCKRecordID()
        return CKReference(recordID: recordID, action: .deleteSelf)
    }
    
    func coreDataShoppingListFrom(ckReference: CKReference, managedObjectContext: NSManagedObjectContext) -> ShoppingList {
        let ckRecordID = ckReference.recordID
        let (entityName, identifier) = splitIntoComponents(recordName: ckRecordID.recordName)
        guard entityName == EntityName.ShoppingList else { fatalError("This parent ref should be ShoppingList") }
        guard let shoppingList = CoreDataUtil.getAShoppingListOf(storeIdentifier: identifier, moc: managedObjectContext) else {
            fatalError("Could not find shoppingList for \(identifier) while searching reference record.")
        }
        return shoppingList
    }
    
    // MARK: - Helper to upload new/update to CloudKit
    // including deletion
    
    func getRecordIDsForDeletion(managedObjectContext: NSManagedObjectContext) -> [CKRecordID]? {
        // gather the recordIDs for deletion
        let deletedShoppingLists = CoreDataUtil.getShoppingListsOf(predicate: Predicates.DeletedShoppingList, moc: managedObjectContext)
        let deletedShoppingListRecordIDs = deletedShoppingLists.map { $0.getCKRecordID() }
        let deletedGroceryItems = CoreDataUtil.getGroceryItems(predicate: Predicates.DeletedGroceryItem, moc: managedObjectContext)
        let deletedGroceryItemRecordIDs = deletedGroceryItems.map { $0.getCKRecordID() }
        
        let deletedRecords = deletedShoppingListRecordIDs + deletedGroceryItemRecordIDs
        
        return deletedRecords == [] ? nil : deletedRecords
    }
    
    func postSuccessfulDeletionOnCloudKit(managedObjectContext: NSManagedObjectContext) {
        // here we delete from core data permanently
        CoreDataUtil.batchDeleteGroceryItemPendingDeletion(managedObjectContext: managedObjectContext)
        CoreDataUtil.batchDeleteShoppingListPendingDeletion(managedObjectContext: managedObjectContext)
    }
    
    func getRecordsToModify(managedObjectContext: NSManagedObjectContext) -> [CKRecord]? {
        // update / modify
        // Create New Records
        let newShoppingLists = CoreDataUtil.getShoppingListsOf(predicate: Predicates.NewShoppingList, moc: managedObjectContext)
        let newShoppingListRecords = newShoppingLists.map { $0.managedObjectToNewCKRecord() }
        let newGroceryItems = CoreDataUtil.getGroceryItems(predicate: Predicates.NewGroceryItem, moc: managedObjectContext)
        let newGroceryItemRecords = newGroceryItems.map { $0.managedObjectToNewCKRecord() }
        
        // Update existing Records
        let updatedShoppingLists = CoreDataUtil.getShoppingListsOf(predicate: Predicates.UpdatedShoppingList, moc: managedObjectContext)
        let updatedShoppingListRecords = updatedShoppingLists.map { $0.managedObjectToUpdatedCKRecord() }
        let updatedGroceryItems = CoreDataUtil.getGroceryItems(predicate: Predicates.UpdatedGroceryItem, moc: managedObjectContext)
        let updatedGroceryItemRecords = updatedGroceryItems.map { $0.managedObjectToUpdatedCKRecord() }
        
        let newAndUpdatedRecords = newShoppingListRecords + newGroceryItemRecords +
                                    updatedShoppingListRecords + updatedGroceryItemRecords
        return newAndUpdatedRecords == [] ? nil : newAndUpdatedRecords
    }
    
    func postSuccessfyModifyOnCloudKit(modifiedCKRecords: [CKRecord], managedObjectContext: NSManagedObjectContext) {
        //  update metadata and modify needsUpload flag
        let modifiedShoppingListCKRecords = modifiedCKRecords.filter { $0.recordType == RecordType.ShoppingList.rawValue }
        let modifiedGroceryItemCKRecords = modifiedCKRecords.filter { $0.recordType == RecordType.GroceryItem.rawValue }
        
        CoreDataUtil.updateShoppingListCKMetadata(from: modifiedShoppingListCKRecords, managedObjectContext: managedObjectContext)
        CoreDataUtil.updateGroceryItemCKMetadata(from: modifiedGroceryItemCKRecords, managedObjectContext: managedObjectContext)
    }
}
