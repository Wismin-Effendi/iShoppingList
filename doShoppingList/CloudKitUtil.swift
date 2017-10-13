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
    
    static let privateDatabase = CKContainer.default().privateCloudDatabase
    
    public static func queryCKRecords(recordType: String, recordZoneID: CKRecordZoneID,
                                      predicate: NSPredicate,
                                      completion: @escaping ([CKRecord]?, Error?) -> Void) {
        
        let privateDatabase = CloudKitUtil.privateDatabase

        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: recordZoneID, completionHandler: completion)
    }
    
    public static func saveOneCKRecord(record: CKRecord, completion: ((Error?) -> ())?) {
        saveOrDeleteCKRecords(recordsToSave: [record], recordIDsToDelete: nil, completion: completion)
    }
    
    public static func saveCKRecords(records: [CKRecord], completion: ((Error?) -> ())?) {
        saveOrDeleteCKRecords(recordsToSave: records, recordIDsToDelete: nil, completion: completion)
    }
    
    public static func deleteCKRecords(recordIDs: [CKRecordID], completion: ((Error?) -> ())?) {
        saveOrDeleteCKRecords(recordsToSave: nil, recordIDsToDelete: recordIDs, completion: completion)
    }
    
    public static func saveOrDeleteCKRecords(recordsToSave: [CKRecord]?, recordIDsToDelete: [CKRecordID]?,
    completion: ((Error?) -> ())? )  {
        let privateDatabase = CloudKitUtil.privateDatabase
        
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave,
                                                              recordIDsToDelete: recordIDsToDelete)
        
        modifyRecordsOperation.timeoutIntervalForRequest = 10
        modifyRecordsOperation.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = { records, recordIDs, error in
            if let err = error {
                os_log("Save Error: %@", err.localizedDescription)
                completion?(err)
            } else {
                os_log("Success: %@", "Record saved/deleted successfully")
            }
            
            completion?(nil)
        }
        
        privateDatabase.add(modifyRecordsOperation)
    }
    
    public static func queryCKRecordsOperation(recordType: String, recordZoneID: CKRecordZoneID,
                                               predicate: NSPredicate,
                                               recordFetchBlockClosure: @escaping (CKRecord) -> Void,
                                               completion: @escaping () -> Void) {
        
        let privateDatabase = CloudKitUtil.privateDatabase
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        let queryRecordsOperation = CKQueryOperation(query: query)
        
        queryRecordsOperation.timeoutIntervalForRequest = 10
        queryRecordsOperation.timeoutIntervalForResource = 10
        queryRecordsOperation.qualityOfService = .userInitiated
        
        queryRecordsOperation.recordFetchedBlock = recordFetchBlockClosure
        
        queryRecordsOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                os_log("Error occured during CKQuery operation: %@", error.localizedDescription)
            }
            
            guard let cursor = cursor else {
                completion()
                return
            }
            
            os_log("More data to fetch")
            fetchMoreRecords(cursor: cursor)
        }
        
        privateDatabase.add(queryRecordsOperation)
        
        
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
    
    public static func modifyRecords(_ records: [CKRecord]?, andDelete deleteIds: [CKRecordID]?,
                                          completionHandler: @escaping ([CKRecord]?, [CKRecordID]?, Error?) -> Void) {
        
        let privateDatabase = CloudKitUtil.privateDatabase
        
        let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: deleteIds)
        op.savePolicy = .allKeys
        op.modifyRecordsCompletionBlock = { (_ savedRecords: [CKRecord]?,
            _ deletedRecordIds: [CKRecordID]?, _ operationError: Error?) -> Void in
            var returnError = operationError
            if let ckerror = operationError as? CKError {
                switch ckerror {
                case CKError.requestRateLimited, CKError.serviceUnavailable, CKError.zoneBusy:
                    let retry = ckerror.retryAfterSeconds ?? 3.0
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + retry, execute: {
                        modifyRecords(records, andDelete: deleteIds, completionHandler: completionHandler)
                    })
                    
                    return
                case CKError.partialFailure:
                    if (savedRecords != nil && savedRecords!.count > 0) ||
                        (deletedRecordIds != nil && deletedRecordIds!.count > 0) {
                        returnError = nil
                    }
                    // during development we want to failed
                    assert(false, "we got partialFailure, need to check for partial records")
                    
                default:
                    break
                }
            }
            
            completionHandler(savedRecords, deletedRecordIds, returnError)
        }
         
        privateDatabase.add(op)
    }
}
