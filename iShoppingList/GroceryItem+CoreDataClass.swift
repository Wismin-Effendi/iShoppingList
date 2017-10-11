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
public class GroceryItem: NSManagedObject, CloudKitConvertible {
    
    func setDefaultValuesForLocalCreation() {
        self.hasReminder =  false
        self.archived =  false
        self.localUpdate = NSDate()
        self.needsUpload = true
        self.pendingDeletion = false
        self.isRepeatedItem = false
        self.repetitionInterval = 0
        self.completed = false
        self.completionDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        self.lastCompletionDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        self.reminderDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        self.lastCompletionDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate

    }
    
    func setDefaultValuesForLocalChange() {
        self.localUpdate = NSDate()
        self.needsUpload = true
        self.pendingDeletion = false 
    }
    
    func setDefaultValuesForCompletion() {
        setDefaultValuesForLocalChange()
        self.completionDate = NSDate()
    }
    
    func setForLocalDeletion() {
        self.needsUpload = false
        self.pendingDeletion = true
        self.localUpdate = NSDate()
    }
    
    func setDefaultValuesForRemoteModify() {
        self.needsUpload = false
        self.pendingDeletion = false
        self.archived = false
        self.localUpdate = NSDate()
    }
}

extension GroceryItem {
    
    convenience init(using cloudKitRecord: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        self.setDefaultValuesForRemoteModify()
        self.identifier = cloudKitRecord[ckGroceryItem.identifier] as! String 
        let ckReference = cloudKitRecord[ckGroceryItem.storeName] as! CKReference
        self.storeName = CoreDataHelper.sharedInstance.coreDataShoppingListFrom(ckReference: ckReference, managedObjectContext: context)
        update(using: cloudKitRecord)
    }
    
    func update(using cloudKitRecord: CKRecord) {
        self.completed = cloudKitRecord[ckGroceryItem.completed] as! Bool
        self.completionDate = (cloudKitRecord[ckGroceryItem.completionDate] as! NSDate)
        self.hasReminder = cloudKitRecord[ckGroceryItem.hasReminder] as! Bool
        self.isRepeatedItem = cloudKitRecord[ckGroceryItem.isRepeatedItem] as! Bool
        self.repetitionInterval = cloudKitRecord[ckGroceryItem.repetitionInterval] as! Double 
        self.lastCompletionDate = (cloudKitRecord[ckGroceryItem.lastCompletionDate] as! NSDate)
        self.reminderDate = (cloudKitRecord[ckGroceryItem.reminderDate] as! NSDate)
        self.title = cloudKitRecord[ckGroceryItem.title] as! String
        self.localUpdate = (cloudKitRecord[ckGroceryItem.localUpdate] as! NSDate)
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: cloudKitRecord)
    }
    
    
    func updateCKMetadata(from ckRecord: CKRecord) {
        self.setDefaultValuesForRemoteModify()
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
        ckRecord[ckGroceryItem.localUpdate] = self.localUpdate
        ckRecord[ckGroceryItem.identifier] = self.identifier as CKRecordValue
        ckRecord[ckGroceryItem.reminderDate] = self.reminderDate
        ckRecord[ckGroceryItem.lastCompletionDate] = self.lastCompletionDate
        ckRecord[ckGroceryItem.isRepeatedItem] = self.isRepeatedItem as CKRecordValue
        ckRecord[ckGroceryItem.repetitionInterval] = self.repetitionInterval as CKRecordValue
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
        ckRecord[ckGroceryItem.localUpdate] = self.localUpdate
        ckRecord[ckGroceryItem.identifier] = self.identifier as CKRecordValue
        ckRecord[ckGroceryItem.reminderDate] = self.reminderDate
        ckRecord[ckGroceryItem.lastCompletionDate] = self.lastCompletionDate
        ckRecord[ckGroceryItem.isRepeatedItem] = self.isRepeatedItem as CKRecordValue
        ckRecord[ckGroceryItem.repetitionInterval] = self.repetitionInterval as CKRecordValue
        ckRecord[ckGroceryItem.hasReminder] = self.hasReminder as CKRecordValue
        ckRecord[ckGroceryItem.completionDate] = self.completionDate
        ckRecord[ckGroceryItem.completed] = self.completed as CKRecordValue
        ckRecord[ckGroceryItem.storeName] = CoreDataHelper.sharedInstance.ckReferenceOf(shoppingList: self.storeName!)
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
