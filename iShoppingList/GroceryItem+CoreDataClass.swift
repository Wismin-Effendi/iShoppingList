//
//  GroceryItem+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(GroceryItem)
public class GroceryItem: NSManagedObject, HasIdentifier {
    
    func setDefaultValuesForLocalCreation() {
        self.needsUpload = true
        self.completed = false
        self.hasReminder =  false
        self.pendingDeletion = false
        self.archived =  false
        self.isRepeatedItem = false
        self.repetitionInterval = 0
        self.lastCompletionDate =  NSDate()
        self.reminderDate = NSDate()
        self.completionDate = NSDate()
        self.localUpdate = NSDate()
    }
    
    func setDefaultValuesForLocalChange() {
        self.localUpdate = NSDate()
        self.needsUpload = true
    }
    
    func setForLocalDeletion() {
        self.needsUpload = true
        self.pendingDeletion = true
        self.localUpdate = NSDate()
    }
    
    func setDefaultValuesForRemoteCreation() {
        self.needsUpload = false
        self.pendingDeletion = false
        self.archived = false
        self.localUpdate = NSDate()
    }
}

extension GroceryItem {
    
    convenience init(using cloudKitRecord: CKRecord, backgroundContext: NSManagedObjectContext) {
        self.init(context: backgroundContext)
        self.setDefaultValuesForRemoteCreation()
        self.identifier = cloudKitRecord.recordID.recordName
        let ckReference = cloudKitRecord[ckGroceryItem.storeName] as! CKReference
        self.storeName = CoreDataHelper.sharedInstance.coreDataShoppingListFrom(ckReference: ckReference, backgroundContext: backgroundContext)
        update(using: cloudKitRecord)
    }
    
    func update(using cloudKitRecord: CKRecord) {
        self.completed = cloudKitRecord[ckGroceryItem.completed] as! Bool
        self.completionDate = (cloudKitRecord[ckGroceryItem.completionDate] as! NSDate)
        self.hasReminder = cloudKitRecord[ckGroceryItem.hasReminder] as! Bool
        self.isRepeatedItem = cloudKitRecord[ckGroceryItem.isRepeatedItem] as! Bool
        self.lastCompletionDate = (cloudKitRecord[ckGroceryItem.lastCompletionDate] as! NSDate)
        self.reminderDate = (cloudKitRecord[ckGroceryItem.reminderDate] as! NSDate)
        self.title = cloudKitRecord[ckGroceryItem.title] as! String
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: cloudKitRecord)
    }
    
    
    func updateCKMetadata(from ckRecord: CKRecord) {
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: ckRecord)
    }
    
    func managedObjectToNewCKRecord() -> CKRecord {
        guard ckMetadata == nil else {
            fatalError("CKMetaData exist, this should is not a new CKRecord")
        }
        
        let recordZoneID = CKRecordZoneID(zoneName: CloudKitZone.iShoppingListZone.rawValue, ownerName: CKCurrentUserDefaultName)
        let recordName = EntityName.GroceryItem + "." +  self.identifier
        let recordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        let ckRecord = CKRecord(recordType: RecordType.GroceryItem.rawValue, recordID: recordID)
        ckRecord[ckGroceryItem.title] = self.title as CKRecordValue
        ckRecord[ckGroceryItem.reminderDate] = self.reminderDate
        ckRecord[ckGroceryItem.lastCompletionDate] = self.lastCompletionDate
        ckRecord[ckGroceryItem.isRepeatedItem] = self.isRepeatedItem as CKRecordValue
        ckRecord[ckGroceryItem.hasReminder] = self.hasReminder as CKRecordValue
        ckRecord[ckGroceryItem.completionDate] = self.completionDate
        ckRecord[ckGroceryItem.completed] = self.completed as CKRecordValue
        ckRecord[ckGroceryItem.storeName] = CoreDataHelper.sharedInstance.ckReferenceOf(shoppingList: self.storeName!)
        return ckRecord
    }
    
    func managedObjectToUpdatedCKRecord() -> CKRecord {
        guard let ckMetadata = self.ckMetadata else {
            fatalError("CKMetadata is required to update CKRecord")
        }
        
        let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
        ckRecord[ckGroceryItem.title] = self.title as CKRecordValue
        ckRecord[ckGroceryItem.reminderDate] = self.reminderDate
        ckRecord[ckGroceryItem.lastCompletionDate] = self.lastCompletionDate
        ckRecord[ckGroceryItem.isRepeatedItem] = self.isRepeatedItem as CKRecordValue
        ckRecord[ckGroceryItem.hasReminder] = self.hasReminder as CKRecordValue
        ckRecord[ckGroceryItem.completionDate] = self.completionDate
        ckRecord[ckGroceryItem.completed] = self.completed as CKRecordValue
        // no need to update storeName as it's not possible
        return ckRecord
    }
    
    func getCKRecordID() -> CKRecordID {
        guard let ckMetadata = self.ckMetadata else {
            fatalError("CKMetaData is required to update CKRecord")
        }
        let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
        return ckRecord.recordID
    }
}
