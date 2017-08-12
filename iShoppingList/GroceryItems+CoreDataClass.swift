//
//  GroceryItems+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(GroceryItems)
public class GroceryItems: NSManagedObject, HasIdentifier {
    
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

extension GroceryItems {
    
    convenience init(using cloudKitRecord: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        self.setDefaultValuesForRemoteCreation()
        self.identifier = cloudKitRecord.recordID.recordName
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
        let recordName = EntityName.GroceryItems + "." +  self.identifier
        let recordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        let ckRecord = CKRecord(recordType: RecordType.GroceryItems.rawValue, recordID: recordID)
        ckRecord[ckGroceryItem.title] = self.title as CKRecordValue
        ckRecord[ckGroceryItem.reminderDate] = self.reminderDate
        ckRecord[ckGroceryItem.lastCompletionDate] = self.lastCompletionDate
        ckRecord[ckGroceryItem.isRepeatedItem] = self.isRepeatedItem as CKRecordValue
        ckRecord[ckGroceryItem.hasReminder] = self.hasReminder as CKRecordValue
        ckRecord[ckGroceryItem.completionDate] = self.completionDate
        ckRecord[ckGroceryItem.completed] = self.completed as CKRecordValue
        
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
        
        return ckRecord
    }
}
