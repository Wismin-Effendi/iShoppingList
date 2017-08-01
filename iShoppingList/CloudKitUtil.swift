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
        let privateDatabase = CloudKitService.sharedInstance.privateDatabase
        
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
        
        privateDatabase?.add(modifyRecordsOperation)
    }
    
    public static func queryCKRecordsOperation(recordType: String, recordZoneID: CKRecordZoneID,
                                               predicate: NSPredicate,
                                               recordFetchBlockClosure: @escaping (CKRecord) -> Void,
                                               completion: @escaping () -> Void) {
        
        let privateDatabase = CloudKitService.sharedInstance.privateDatabase
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        let queryRecordsOperation = CKQueryOperation(query: query)
        
        queryRecordsOperation.timeoutIntervalForRequest = 10
        queryRecordsOperation.timeoutIntervalForResource = 10
        queryRecordsOperation.qualityOfService = .userInitiated
        
        queryRecordsOperation.recordFetchedBlock = recordFetchBlockClosure
        
        queryRecordsOperation.queryCompletionBlock = { cursor, error in
            guard let cursor = cursor else {
                completion()
                return
            }
            
            os_log("More data to fetch")
            fetchMoreRecords(cursor: cursor)
        }
        
        privateDatabase?.add(queryRecordsOperation)
        
        
        func fetchMoreRecords(cursor: CKQueryCursor?) {
            let queryOperation = CKQueryOperation(cursor: cursor!)
            queryOperation.qualityOfService = .userInitiated
            queryOperation.recordFetchedBlock = recordFetchBlockClosure
            
            queryOperation.queryCompletionBlock = { cursor, error in
                guard let cursor = cursor else {
                    completion() 
                    return
                }
                
                fetchMoreRecords(cursor: cursor)
            }
        }
    }
}
