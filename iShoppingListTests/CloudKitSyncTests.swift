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
        case GroceryItem
        case WarehouseGroceryItems
    }
    
    let cloudKitService = CloudKitService.sharedInstance
    var recordZoneID: CKRecordZoneID!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        self.recordZoneID = cloudKitService.recordZoneID
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
                    print("Creation date: \(result.creationDate!)")
                    print("Modified date: \(result["localUpdate"])")
                    print("Modified keys: \(result.changedKeys())")
                }
            } else {
                os_log("No Match Found: %@", "No record matching the address was found")
            }
            queryWithSomeResultsExpectation.fulfill()
        }
        wait(for: [queryWithSomeResultsExpectation], timeout: 10)
    }
    
    func testQueryOperationShoppingList_HMart() {
        
        func processEachRecord(_ record: CKRecord) {
            print("All keys: \(record.allKeys())")
            print("RecordID: \(record.recordID.recordName)")
            print("Modified date: \(record[ckShoppingList.localUpdate])")
        }
        
        // Query ShoppingList HMart and process each records
        let queryWithSomeResultsExpectation = expectation(description: "Query with some results")
        CloudKitUtil.queryCKRecordsOperation(recordType: EntityName.ShoppingList,
                                             recordZoneID: recordZoneID,
                                             predicate: NSPredicate.init(format: "title == %@", "H-Mart"),
                                             recordFetchBlockClosure: processEachRecord(_:),
                                             completion: { queryWithSomeResultsExpectation.fulfill() })
        wait(for: [queryWithSomeResultsExpectation], timeout: 10)
    }
    
    func testAddMoreShoppingListRecordInCloudKitThenDeleteAll() {
        
        
        let recordZoneID = cloudKitService.recordZoneID
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
        
        CloudKitUtil.deleteCKRecords(recordIDs: recordIDs, completion: { error in
            deleteExpectation.fulfill()
            if error != nil {
                os_log("Error: %@" , error!.localizedDescription)
            }
        })
        
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
        let recordZoneID = cloudKitService.recordZoneID
        
        let uploadExpectation = expectation(description: "Record saved to CloudKit")
        
        let myRecord = createCKRecord(recordType: .ShoppingList, title: title, zoneID: recordZoneID)
            
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
        
        modifyRecordsOperation.savePolicy = .ifServerRecordUnchanged
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = {[weak self] records, recordIDs, error in
            if let err = error {
                os_log("Save Error: %@", err.localizedDescription)
            } else {
                os_log("Success: %@", "Record saved successfully")
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
    
    func testCreateSubscription() {
        let group = DispatchGroup()
        let subscription = CKRecordZoneSubscription.init(zoneID: recordZoneID, subscriptionID: "recordZoneSubscription")
        
        group.enter()
        cloudKitService.privateDatabase?.save(subscription, completionHandler: { (subscription: CKSubscription?, error: Error?) in
            
            if error != nil {
                print(error.debugDescription)
            }
            group.leave()
        })
        let result = group.wait(timeout: DispatchTime.now() + 5)
        switch result {
        case .timedOut:
            os_log("Failed")
        case .success:
            os_log("Success")
        }
    }
    
    func testRemoveSubscription() {
        let group = DispatchGroup()
        group.enter()
        cloudKitService.privateDatabase?.delete(withSubscriptionID: "recordZoneSubscription", completionHandler: { (subscriptionID: String?, error: Error?) in
            
            print(subscriptionID)
            print(error.debugDescription)
            group.leave()
        })
        group.wait(timeout: DispatchTime.now() + 5)
    }
    

    func testRecordChangeNotification() {
        let fetchNotifExpectation = expectation(description: "fetchNotification")
        
        var serverChangeToken: CKServerChangeToken!
        let backgroundContext = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList).newBackgroundContext()
        
        let operation = CKFetchNotificationChangesOperation()
        operation.fetchNotificationChangesCompletionBlock = { serverToken, error in
            guard error == nil else {
                print("(error.debugdescription)")
                fetchNotifExpectation.fulfill()
                return
            }
            
            if let token = serverToken {
                serverChangeToken = token
                print(token.debugDescription)
                print(token.hashValue)
            }
            fetchNotifExpectation.fulfill()
        }
        let opQueue = OperationQueue()
        opQueue.addOperation(operation)
        
        wait(for: [fetchNotifExpectation], timeout: 10)
        
        CoreDataUtil.setPreviousServerChangeToken(previousServerChangeToken: serverChangeToken!, moc: backgroundContext)
        
        
        let retrievedData = CoreDataUtil.getPreviousServerChangeToken(moc: backgroundContext)
        print(retrievedData)
        XCTAssertEqual(serverChangeToken, retrievedData)
    }
    
    func testSaveCKServerChangeToken() {
        
        let tokenUpdateExpectation = expectation(description: "Accept Server Token Update")
        var serverToken: CKServerChangeToken?
        let backgroundContext = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList).newBackgroundContext()
        

        // add some CKRecord
        testCreateMultipleShoppingListRecordInCloudKit()
        
        // CoreDataUtil.deletePreviousServerChangeToken(moc: backgroundContext)
        
        
        serverToken = CoreDataUtil.getPreviousServerChangeToken(moc: backgroundContext)
        
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = serverToken
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [recordZoneID], optionsByRecordZoneID: [recordZoneID: options])
        
        operation.recordChangedBlock = { record in
            print(record)
        }
        
        operation.recordZoneFetchCompletionBlock = { zoneID, serverToken, clientToken, moreComing, error in
            guard error == nil else {
                print("Zone error: \(error.debugDescription)")
                return
            }
            
            print("Latest serverToken: \(serverToken)")
            CoreDataUtil.setPreviousServerChangeToken(previousServerChangeToken: serverToken!, moc: backgroundContext)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { _, ckServerChangeToken, data in

            serverToken = ckServerChangeToken
            print("hi there, we are here...")
            print("we got ... \(ckServerChangeToken)")
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            if error != nil { print(error.debugDescription) }
            print("We are here....")
            tokenUpdateExpectation.fulfill()
        }
        
        cloudKitService.privateDatabase?.add(operation)
        
        wait(for: [tokenUpdateExpectation], timeout: 60)
    
    }
    
}
