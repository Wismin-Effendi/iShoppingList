//
//  ShoppingList+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(ShoppingList)
public class ShoppingList: NSManagedObject, CloudKitConvertible {

}

extension ShoppingList {
    convenience init(using cloudKitRecord: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        update(using: cloudKitRecord)
    }
    
    func setDefaultValuesForLocalCreation() {
        self.localUpdate = NSDate()
        self.pendingDeletion = false
        self.needsUpload = true
    }
    
    func setForLocalDeletion() {
        self.needsUpload = false
        self.pendingDeletion = true
        self.localUpdate = NSDate()
    }
    
    func update(using cloudKitRecord: CKRecord) {
        self.title = cloudKitRecord[ckShoppingList.title] as! String
        self.needsUpload = false
        self.pendingDeletion = false
        self.identifier = cloudKitRecord[ckShoppingList.identifier] as! String
        self.localUpdate = (cloudKitRecord[ckShoppingList.localUpdate] as! NSDate)
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: cloudKitRecord)
     
        try! self.managedObjectContext?.save()
    }
    
    func updateCKMetadata(from ckRecord: CKRecord) {
        self.ckMetadata = CloudKitHelper.encodeMetadata(of: ckRecord)
        self.needsUpload = false
        
        try! self.managedObjectContext?.save()
    }
    
    func managedObjectToNewCKRecord() -> CKRecord {
        guard ckMetadata == nil else {
            fatalError("CKMetaData exist, this should is not a new CKRecord")
        }
        
        let recordZoneID = CKRecordZoneID(zoneName: CloudKitZone.iShoppingListZone.rawValue, ownerName: CKCurrentUserDefaultName)
        let recordName = EntityName.ShoppingList + "." + self.identifier
        let recordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        let ckRecord = CKRecord(recordType: RecordType.ShoppingList.rawValue, recordID: recordID)
        ckRecord[ckShoppingList.title] = self.title as CKRecordValue
        ckRecord[ckShoppingList.identifier] = self.identifier as CKRecordValue
        ckRecord[ckShoppingList.localUpdate] = self.localUpdate
        
        return ckRecord
    }
    
    func managedObjectToUpdatedCKRecord() -> CKRecord {
        guard let ckMetadata = self.ckMetadata else {
            fatalError("CKMetaData is required to update CKRecord")
        }
        
        let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
        ckRecord[ckShoppingList.title] = self.title as CKRecordValue
        ckRecord[ckShoppingList.identifier] = self.identifier as CKRecordValue
        ckRecord[ckShoppingList.localUpdate] = self.localUpdate
        
        return ckRecord
    }
    
    func getCKRecordID() -> CKRecordID {
        let ckRecordID: CKRecordID
        if let ckMetadata = self.ckMetadata  {
            let ckRecord = CloudKitHelper.decodeMetadata(from: ckMetadata as! NSData)
            ckRecordID = ckRecord.recordID
        } else {
            let recordZoneID = CKRecordZoneID(zoneName: CloudKitZone.iShoppingListZone.rawValue, ownerName: CKCurrentUserDefaultName)
            let recordName = EntityName.ShoppingList + "." + self.identifier
            ckRecordID = CKRecordID(recordName: recordName, zoneID: recordZoneID)
        }
        return ckRecordID
    }
}
