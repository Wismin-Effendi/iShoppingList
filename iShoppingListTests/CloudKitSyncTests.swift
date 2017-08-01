//
//  CloudKitSyncTests.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/31/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import XCTest
import CloudKit
import os.log

@testable import iShoppingList

class CloudKitSyncTests: XCTestCase {
    
    enum RecordType: String {
        case ShoppingList
        case GroceryItems
        case WarehouseGroceryItems
    }
    
    let cloudKitService = CloudKitService.sharedInstance
    var recordZoneID: CKRecordZoneID!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        if let recordZoneID = cloudKitService.recordZoneID {
            self.recordZoneID = recordZoneID
        }
        else {
            fatalError("Abort. No record zone.")
        }
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testCreateMultipleShoppingListRecordInCloudKit() {
        
        for title in ["H-Mart", "Costco", "Sam's Club"] {
            let newExpectation = expectation(description: "Create new record")
            createOneShoppingListRecordInCloudKit(title: title, completion: { newExpectation.fulfill() } )
            wait(for: [newExpectation], timeout: 10)
        }
        
    }
    
    func testQueryShoppingList_HMart() {
        
        // Query ShoppingList HMart and save the recordIDs
        let queryWithSomeResultsExpectation = expectation(description: "Query with some results")
        CloudKitUtil.queryCKRecords(recordType: EntityName.ShoppingList,
                                    recordZoneID: recordZoneID,
                                    predicate: NSPredicate.init(format: "title == %@", "H-Mart"))
        { (results, error) in
            if (error != nil) {
                os_log("Cloud Access Error: %@", error!.localizedDescription)
            }
            
            guard let results = results else { return }
            
            if results.count > 0 {
                for result in results {
                    print("All keys: \(result.allKeys())")
                    print("Creation date: \(result.creationDate)")
                    print("Modified date: \(result.modificationDate)")
                    print("Modified keys: \(result.changedKeys())")
                }
            } else {
                os_log("No Match Found: %@", "No record matching the address was found")
            }
            queryWithSomeResultsExpectation.fulfill()
        }
        wait(for: [queryWithSomeResultsExpectation], timeout: 10)
    }
    
    func testAddMoreShoppingListRecordInCloudKitThenDeleteAll() {
        
        
        guard let recordZoneID = cloudKitService.recordZoneID else {
            os_log("Abort. No record zone.")
            return
        }

        var recordIDs = [CKRecordID]()
        
        
        for title in ["Rose", "Marshal", "JC Penny", "Dollar Tree", "HEB", "Walmart", "BH Photo", "Adorama", "Apple Store"] {
            let newExpectation = expectation(description: "Create new record")
            createOneShoppingListRecordInCloudKit(title: title, completion: { newExpectation.fulfill() } )
            wait(for: [newExpectation], timeout: 10)
        }
        
        sleep(2)
        // Query all ShoppingList and save the recordIDs
        let queryWithSomeResultsExpectation = expectation(description: "Query with some results")
        CloudKitUtil.queryCKRecords(recordType: EntityName.ShoppingList,
                                    recordZoneID: recordZoneID,
                                    predicate: NSPredicate.init(format: "TRUEPREDICATE"))
        { (results, error) in
            if (error != nil) {
                os_log("Cloud Access Error: %@", error!.localizedDescription)
            }
            
            guard let results = results else { return }
            
            if results.count > 0 {
                let count = results.count
                XCTAssert(count >= 3, "We should have at least Rose, Marshal, JC Penny in CloudKit")
                recordIDs = results.map { $0.recordID }
                print("Going to delete \(count) records")
            } else {
                XCTAssert(false, "We should have at least Rose, Marshal, JC Penny in CloudKit")
                os_log("No Match Found: %@", "No record matching the address was found")
            }
            queryWithSomeResultsExpectation.fulfill()
        }
        wait(for: [queryWithSomeResultsExpectation], timeout: 10)
        
        // Delete all ShoppingList from CloudKit
        let deleteExpectation = expectation(description: "Delete all shopping list records")
        
        CloudKitUtil.deleteCKRecords(recordIDs: recordIDs, completion: { deleteExpectation.fulfill() })
        
        wait(for: [deleteExpectation], timeout: 10)
        os_log("We should have no record at this time")

        sleep(1)
        // Query again 
        let queryWithNoResult = expectation(description: "Query with no results")
        CloudKitUtil.queryCKRecords(recordType: EntityName.ShoppingList,
                                    recordZoneID: recordZoneID,
                                    predicate: NSPredicate.init(format: "TRUEPREDICATE"))
        { (results, error) in
            if (error != nil) {
                os_log("Cloud Access Error: %@", error!.localizedDescription)
            }
            
            guard let results = results else { return }
            
            if results.count > 0 {
                XCTAssert(false, "We should have no more records")
                recordIDs = results.map { $0.recordID }
            } else {
                XCTAssert(results.count == 0, "We should have no more records")
                os_log("No Match Found: %@", "No record matching the address was found")
            }
            queryWithNoResult.fulfill()
        }
        wait(for: [queryWithNoResult], timeout: 10)

        // Query again
        let queryWithNoResult2 = expectation(description: "Query with no results")
        CloudKitUtil.queryCKRecords(recordType: EntityName.ShoppingList,
                                    recordZoneID: recordZoneID,
                                    predicate: NSPredicate.init(format: "TRUEPREDICATE"))
        { (results, error) in
            if (error != nil) {
                os_log("Cloud Access Error: %@", error!.localizedDescription)
            }
            
            guard let results = results else { return }
            
            if results.count > 0 {
                XCTAssert(false, "We should have no more records")
                recordIDs = results.map { $0.recordID }
            } else {
                XCTAssert(results.count == 0, "We should have no more records")
                os_log("No Match Found: %@", "No record matching the address was found")
            }
            queryWithNoResult2.fulfill()
        }
        wait(for: [queryWithNoResult2], timeout: 10)
    }
    
    
    func createOneShoppingListRecordInCloudKit(title: String, completion: (() -> ())?) {
        // Note: Here we use CKModifyRecordsOperation that will modify all records at once.
        // so the following will only create / modify one record in recordType. 
        // To create multiple records, use .saveRecord instead.
        guard let recordZoneID = cloudKitService.recordZoneID else {
            fatalError("Abort. No record zone.")
        }

        let uploadExpectation = expectation(description: "Record saved to CloudKit")
        
        let myRecord = createCKRecord(recordType: .ShoppingList, title: title, zoneID: recordZoneID)
            
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
        
        modifyRecordsOperation.timeoutIntervalForRequest = 10
        modifyRecordsOperation.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = {[weak self] records, recordIDs, error in
            if let err = error {
                os_log("Save Error: %@", err.localizedDescription)
            } else {
                os_log("Success: %@", "Record saved successfully")
                self?.cloudKitService.currentRecord = myRecord
            }
            XCTAssertTrue(error == nil)
            XCTAssertTrue(records != nil)
            uploadExpectation.fulfill()
            
            completion?()
        }
        cloudKitService.privateDatabase?.add(modifyRecordsOperation)
        
        wait(for: [uploadExpectation], timeout: 20)
    }
    
    func createCKRecord(recordType: RecordType, title: String, zoneID: CKRecordZoneID) -> CKRecord {
        let myRecord = CKRecord(recordType: recordType.rawValue, zoneID: zoneID)
        myRecord.setObject(title as CKRecordValue?, forKey: "title")
        myRecord.setObject(UUID().uuidString as CKRecordValue?, forKey: "identifier")
        myRecord.setObject(true as CKRecordValue?, forKey: "synced")
        
        return myRecord
    }
}
