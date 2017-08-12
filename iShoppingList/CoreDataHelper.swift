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
                let shoppingList = CoreDataUtil.getAShoppingListOf(storeIdentifier: storeIdentifier, moc: backgroundContext) {
                shoppingList.update(using: ckRecord)
            } else {
                let _ = ShoppingList.init(using: ckRecord, context: backgroundContext)
            }
        case EntityName.GroceryItem:
            if let identifier = ckRecord[ckGroceryItem.identifier] as? String,
                let groceryItem = CoreDataUtil.getGroceryItem(identifier: identifier, moc: backgroundContext) {
                groceryItem.update(using: ckRecord)
            } else{
                let _ = GroceryItem.init(using: ckRecord, backgroundContext: backgroundContext)
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
        case EntityName.GroceryItem:
            CoreDataUtil.deleteGroceryItem(identifier: identifier, moc: backgroundContext)
        default:
            fatalError("Unexpected entityName: \(entityName)")
        }
    }
    
    func ckReferenceOf(shoppingList: ShoppingList) -> CKReference {
        let recordID = shoppingList.getCKRecordID()
        return CKReference(recordID: recordID, action: .deleteSelf)
    }
    
    func coreDataShoppingListFrom(ckReference: CKReference, backgroundContext: NSManagedObjectContext) -> ShoppingList {
        let ckRecordID = ckReference.recordID
        let (entityName, identifier) = splitIntoComponents(recordName: ckRecordID.recordName)
        guard entityName == EntityName.ShoppingList else { fatalError("This parent ref should be ShoppingList") }
        guard let shoppingList = CoreDataUtil.getAShoppingListOf(storeIdentifier: identifier, moc: backgroundContext) else {
            fatalError("Could not find shoppingList for \(identifier) while searching reference record.")
        }
        return shoppingList
    }
    
    // MARK: - Helper to upload new/update to CloudKit
    // including deletion
    
    func getRecordIDsForDeletion(backgroundContext: NSManagedObjectContext) -> [CKRecordID]? {
        // gather the recordIDs for deletion
        let deletedShoppingLists = CoreDataUtil.getShoppingListsOf(predicate: Predicates.DeletedShoppingList, moc: backgroundContext)
        let deletedShoppingListRecordIDs = deletedShoppingLists.map { $0.getCKRecordID() }
        let deletedGroceryItems = CoreDataUtil.getGroceryItems(predicate: Predicates.DeletedGroceryItem, moc: backgroundContext)
        let deletedGroceryItemRecordIDs = deletedGroceryItems.map { $0.getCKRecordID() }
        
        let deletedRecords = deletedShoppingListRecordIDs + deletedGroceryItemRecordIDs
        
        return deletedRecords == [] ? nil : deletedRecords
    }
    
    func postSuccessfulDeletionOnCloudKit(backgroundContext: NSManagedObjectContext) {
        // here we delete from core data permanently
        CoreDataUtil.batchDeleteGroceryItemPendingDeletion(backgroundContext: backgroundContext)
        CoreDataUtil.batchDeleteShoppingListPendingDeletion(backgroundContext: backgroundContext)
    }
    
    func getRecordsToModify(backgroundContext: NSManagedObjectContext) -> [CKRecord]? {
        // update / modify
        // Create New Records
        let newShoppingLists = CoreDataUtil.getShoppingListsOf(predicate: Predicates.NewShoppingList, moc: backgroundContext)
        let newShoppingListRecords = newShoppingLists.map { $0.managedObjectToNewCKRecord() }
        let newGroceryItems = CoreDataUtil.getGroceryItems(predicate: Predicates.NewGroceryItem, moc: backgroundContext)
        let newGroceryItemRecords = newGroceryItems.map { $0.managedObjectToNewCKRecord() }
        
        // Update existing Records
        let updatedShoppingLists = CoreDataUtil.getShoppingListsOf(predicate: Predicates.UpdatedShoppingList, moc: backgroundContext)
        let updatedShoppingListRecords = updatedShoppingLists.map { $0.managedObjectToUpdatedCKRecord() }
        let updatedGroceryItems = CoreDataUtil.getGroceryItems(predicate: Predicates.UpdatedGroceryItem, moc: backgroundContext)
        let updatedGroceryItemRecords = updatedGroceryItems.map { $0.managedObjectToUpdatedCKRecord() }
        
        let newAndUpdatedRecords = newShoppingListRecords + newGroceryItemRecords +
                                    updatedShoppingListRecords + updatedGroceryItemRecords
        return newAndUpdatedRecords == [] ? nil : newAndUpdatedRecords
    }
    
    func postSuccessfyModifyOnCloudKit(modifiedCKRecords: [CKRecord], backgroundContext: NSManagedObjectContext) {
        //  update metadata and modify needsUpload flag
        let modifiedShoppingListCKRecords = modifiedCKRecords.filter { $0.recordType == RecordType.ShoppingList.rawValue }
        let modifiedGroceryItemCKRecords = modifiedCKRecords.filter { $0.recordType == RecordType.GroceryItem.rawValue }
        
        CoreDataUtil.updateShoppingListCKMetadata(from: modifiedShoppingListCKRecords, backgroundContext: backgroundContext)
        CoreDataUtil.updateGroceryItemCKMetadata(from: modifiedGroceryItemCKRecords, backgroundContext: backgroundContext)
    }
}
