//
//  CloudKitUtil.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/31/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CloudKit
import os.log

class CloudKitUtil {
    
    public static func queryCKRecords(recordType: String, recordZoneID: CKRecordZoneID,
                                      predicate: NSPredicate,
                                      completion: @escaping ([CKRecord]?, Error?) -> Void) {
        
        let privateDatabase = CloudKitService.sharedInstance.privateDatabase

        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        privateDatabase?.perform(query, inZoneWith: recordZoneID, completionHandler: completion)
    }
    
    public static func saveOneCKRecord(record: CKRecord, completion: (() -> ())?) {
        saveOrDeleteCKRecords(recordsToSave: [record], recordIDsToDelete: nil, completion: completion)
    }
    
    public static func saveCKRecords(records: [CKRecord], completion: (() -> ())?) {
        saveOrDeleteCKRecords(recordsToSave: records, recordIDsToDelete: nil, completion: completion)
    }
    
    public static func deleteCKRecords(recordIDs: [CKRecordID], completion: (() -> ())?) {
        saveOrDeleteCKRecords(recordsToSave: nil, recordIDsToDelete: recordIDs, completion: completion)
    }
    
    public static func saveOrDeleteCKRecords(recordsToSave: [CKRecord]?, recordIDsToDelete: [CKRecordID]?,
    completion: (() -> ())? )  {
        let cloudKitService = CloudKitService.sharedInstance
        
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave,
                                                              recordIDsToDelete: recordIDsToDelete)
        
        modifyRecordsOperation.timeoutIntervalForRequest = 10
        modifyRecordsOperation.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = { records, recordIDs, error in
            if let err = error {
                os_log("Save Error: %@", err.localizedDescription)
            } else {
                os_log("Success: %@", "Record saved/deleted successfully")
            }
            
            completion?()
        }
        cloudKitService.privateDatabase?.add(modifyRecordsOperation)
    }
}
