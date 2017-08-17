//
//  CloudKitHelper.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/4/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import os.log


enum CloudKitUserDefaults: String {
    case createdCustomzone
    case subscribedToPrivateChanges
    case subscribedToSharedChanges
}

enum CustomCKError: Error {
    case fetchZoneError(Error)
    case createZoneError(Error)
}

enum ServerChangeToken: String {
    case DatabaseChangeToken
    case ZoneChangeToken
}


class CloudKitHelper {
// Initializing Container 
    
    let coreDataHelper = CoreDataHelper.sharedInstance
    let container = CKContainer.default()
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let sharedDB: CKDatabase = CKContainer.default().sharedCloudDatabase
    let privateSubscriptionID = "private-changes"
    let sharedSubscriptionID = "shared-changes"
    
    let zoneKeyPrefix = "token4Zone-"
    let createdZoneGroup = DispatchGroup()
    
    let zoneID: CKRecordZoneID = CloudKitZone.iShoppingListZone.recordZoneID()
    
    var fetchAllZonesOperations: CKFetchRecordZonesOperation!
    var modifyRecordZonesOperation: CKModifyRecordZonesOperation!
    var createPrivateDBSubscriptionOperation: CKModifySubscriptionsOperation!
    var createSharedDBSubscriptionOperation: CKModifySubscriptionsOperation!
    var saveToCloudKitOperation: CKModifyRecordsOperation!
    var fetchDatabaseChangesoperation: CKFetchDatabaseChangesOperation!
    var fetchRecordZoneChangesoperation: CKFetchRecordZoneChangesOperation!
    
    var databaseChangeToken: CKServerChangeToken? = nil
    var isRetryOperation = false
    
    // default to `false`
    var createdCustomZone = false
    var subscribedToPrivateChanges = false
    var subscribedToSharedChanges = false
    
    // we need to keep the reference for NSOperations around, so we use properties as their references
    var fetchRecordZoneOperation: CKFetchRecordZonesOperation?
    
    // Singleton
    static var sharedInstance = CloudKitHelper()

    let managedObjectContext: NSManagedObjectContext
    
    private init() {
        managedObjectContext = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList).managedObjectContext
    }
    
    
    func sayHello() {
        print("Hello world")
    }
    
    //MARK: - Modify custom zone to match CloudKitZones enums
    //
    
    // main function
    func setCustomZonesCompliance() {
        // The following should run in strict order, use DispatchGroup and Wait to sync the process
        // 1. run fetch allZone (see helper func above)
        // 2. create zonesToCreate and zonesToDelete
        
        var recordZonesToSave: [CKRecordZone]?
        var recordZoneIDsToDelete: [CKRecordZoneID]?
        
        func processServerRecordZone(existingZoneIDs: [CKRecordZoneID]) -> ([CKRecordZone]?, [CKRecordZoneID]?) {
            
            func setZonesToCreate() -> [CKRecordZone]? {
                var recordZonesToCreate: [CKRecordZone]? = nil
                let existingZoneNames = existingZoneIDs.map {  $0.zoneName }
                let expectedZoneNamesSet = Set(CloudKitZone.allCloudKitZoneNames)
                let missingZoneNamesSet = expectedZoneNamesSet.subtracting(existingZoneNames)
                
                if missingZoneNamesSet.count > 0 {
                    recordZonesToCreate = missingZoneNamesSet.flatMap( { CloudKitZone(rawValue: $0) } )
                        .map { CKRecordZone(zoneID: $0.recordZoneID()) }
                }
                return recordZonesToCreate
            }
            
            func setZoneIDstoDelete() -> [CKRecordZoneID]? {
                var recordZoneIDsToDelete: [CKRecordZoneID]? = nil
                let customZoneIDsOnly = existingZoneIDs.filter { $0.zoneName != CKRecordZoneDefaultName }
                recordZoneIDsToDelete = customZoneIDsOnly.filter { CloudKitZone(rawValue: $0.zoneName) == nil }
                // we should return either nil or array with at least 1 member never empty array
                recordZoneIDsToDelete = recordZoneIDsToDelete!.isEmpty ? nil : recordZoneIDsToDelete
                return recordZoneIDsToDelete
            }
            
            return (setZonesToCreate(), setZoneIDstoDelete())
        }
        
        func fetchAndProcessRecordZones() {
            var existingZoneIDs = [CKRecordZoneID]()
            fetchAllZonesOperations = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
            fetchAllZonesOperations.fetchRecordZonesCompletionBlock = {[unowned self] recordZoneDict, error in
                
                guard error == nil else {
                    os_log("Error occured during fetch record zones operation: %s", error!.localizedDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: self.setCustomZonesCompliance)
                    return
                }
                
                existingZoneIDs = Array(recordZoneDict!.keys)
                os_log("Existing zones: %@", existingZoneIDs.map { $0.zoneName } )
                (recordZonesToSave, recordZoneIDsToDelete) = processServerRecordZone(existingZoneIDs: existingZoneIDs)
            }
            privateDB.add(fetchAllZonesOperations)
        }

        
        // 3. run modifyRecordZone operation to create and delete zone for compliance
        func modifyRecordZones(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZoneID]?) {
            modifyRecordZonesOperation = CKModifyRecordZonesOperation(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
            modifyRecordZonesOperation.addDependency(fetchAllZonesOperations)
            if isRetryOperation { isRetryOperation = false } // need to reset the flag eventhough we don't use it here
            modifyRecordZonesOperation.modifyRecordZonesCompletionBlock = {[unowned self] modifiedRecordZones, deletedRecordZoneIDs, error in
                
                os_log("--CKModifyRecordZonesOperation.modifyRecordZonesOperation")

                guard error == nil else {
                    os_log("Error occured during modify record zones operation: %s", error!.localizedDescription)
                    
                    self.handlingCKOperationError(of: error!, retryableFunction: self.setCustomZonesCompliance)
                    return
                }
                
                
                if let modifiedRecordZones = modifiedRecordZones {
                    modifiedRecordZones.forEach { os_log("Added recordZone: %@", $0) }
                }
                
                if let deletedRecordZoneIDs = deletedRecordZoneIDs {
                    deletedRecordZoneIDs.forEach { os_log("Deleted zoneID: %@", $0) }
                }
                
                self.createdCustomZone = true
                self.isRetryOperation = false
            }
            privateDB.add(modifyRecordZonesOperation)
        }
        
        fetchAndProcessRecordZones()
        modifyRecordZones(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
        
    }
    
    
    // MARK: - Subcribing to Change Notification
    // create subscription if not exists
    func createDBSubscription() {
        subscribedToPrivateChanges = false
        subscribedToSharedChanges = false

        print("create private")
        createPrivateDBSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: privateSubscriptionID)
        if !isRetryOperation {
            createPrivateDBSubscriptionOperation.addDependency(modifyRecordZonesOperation)
        } else {
            isRetryOperation = false
        }
        createPrivateDBSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
            guard error == nil else {
                os_log("Error occured during modify record zones operation: %s", error!.localizedDescription)
                
                self.handlingCKOperationError(of: error!, retryableFunction: self.createDBSubscription)
                return
            }
            
            self.subscribedToPrivateChanges = true

        }
        privateDB.add(createPrivateDBSubscriptionOperation)
    
        print("create shared")
        createSharedDBSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: sharedSubscriptionID)
        createSharedDBSubscriptionOperation.addDependency(createPrivateDBSubscriptionOperation)
        createSharedDBSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
            guard error == nil else {
                os_log("Error occured during modify record zones operation: %s", error!.localizedDescription)
                
                self.handlingCKOperationError(of: error!, retryableFunction: self.createDBSubscription)
                return
            }
            self.subscribedToSharedChanges = true
            
        }
        sharedDB.add(createSharedDBSubscriptionOperation)

    }
    
    
    // MARK: - Fetch from CloudKit and Save to CloudKit
    func syncToCloudKit(fetchCompletion: @escaping () -> Void) {
        fetchOfflineServerChanges(completion: fetchCompletion)
        saveLocalChangesToCloudKit()
    }
    
    private func fetchOfflineServerChanges(completion: @escaping () -> Void) {
        print(self.createdCustomZone)
        createdZoneGroup.notify(queue: DispatchQueue.global()) { [unowned self] in
            self.fetchChanges(in: .private, completion: completion)
        }
    }
    
    func createDatabaseSubscriptionOperation(subscriptionID: String) -> CKModifySubscriptionsOperation {
        let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionID)
        
        let notificationInfo = CKNotificationInfo()
        
        // send a silent notification 
        
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        
        return operation
    }
    
    
    
    func fetchChanges(in databaseScope: CKDatabaseScope, completion: @escaping () -> Void) {
    
        switch databaseScope {
        case .private:
            fetchDatabaseChanges(database: self.privateDB, databaseTokenKey: "private", completion: completion)
        case .shared:
            fetchDatabaseChanges(database: self.sharedDB, databaseTokenKey: "shared", completion: completion)
        case .public:
            fatalError()
        }
        
    }
    
    func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping () -> Void) {
        
        print("we are in fetch DB change for")
        
     //   let group = DispatchGroup()
        
        var changedZoneIDs = [CKRecordZoneID]()
        
        let changeToken: CKServerChangeToken? = {
            guard let data = UserDefaults.standard.data(forKey: ServerChangeToken.DatabaseChangeToken.rawValue) else { return nil }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
        }()
        
        if let changeToken = changeToken {
            print(changeToken)
        } else {
            print("Change token is nil")
        }
        
        
        fetchDatabaseChangesoperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        if !subscribedToPrivateChanges {
            fetchDatabaseChangesoperation.addDependency(createPrivateDBSubscriptionOperation)
        }
        
        fetchDatabaseChangesoperation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        
        fetchDatabaseChangesoperation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // write this zone deletion to memory
        }
        
        fetchDatabaseChangesoperation.changeTokenUpdatedBlock = {[unowned self] (token) in
            // Flush zone deletion for this database to disk 
            // Write this new database change token to memory 
            
            self.databaseChangeToken = token
            
            let data = NSKeyedArchiver.archivedData(withRootObject: token)
            UserDefaults.standard.set(data, forKey: ServerChangeToken.DatabaseChangeToken.rawValue)
            UserDefaults.standard.synchronize()
        }
        
        
        fetchDatabaseChangesoperation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                print("Error during fetch database changes operation", error)
                completion()
                return
            }
            guard error == nil else {
                os_log("Error occured during fetch database changes operations: %s", error!.localizedDescription)
                
                self.handlingCKOperationError(of: error!, retryableFunction: self.saveLocalChangesToCloudKit)
                completion()
                return
            }
            
            print("We are in fetch db changes completion block..")
            
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            if let token = token {
                let data = NSKeyedArchiver.archivedData(withRootObject: token)
                UserDefaults.standard.set(data, forKey: ServerChangeToken.DatabaseChangeToken.rawValue)
                UserDefaults.standard.synchronize()
            }
            
            self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
                // Flush in memory database change token to disk

                os_log("We are done with fetch zone changes....")
                completion()
            }
            
        }
        print("are we here...?")
        database.add(fetchDatabaseChangesoperation)
    }
    
    
    func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZoneID],
                          completion: @escaping () -> Void) {
        
        // Look up the previous change token for each zone 
        
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        
        for zoneID in zoneIDs {
            
            let options = CKFetchRecordZoneChangesOptions()
            options.previousServerChangeToken = {
                let zoneKey =  zoneKeyPrefix + "\(zoneID.zoneName)"
                guard let data = UserDefaults.standard.data(forKey: zoneKey) else { return nil }
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken
            }()
        
            optionsByRecordZoneID[zoneID] = options
        }
        
        fetchRecordZoneChangesoperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
        
        fetchRecordZoneChangesoperation.recordChangedBlock = {[unowned self] (ckRecord: CKRecord) in
            print("Record changed:", ckRecord)
            // Write this record change to memory 
            self.coreDataHelper.insertOrUpdateManagedObject(using: ckRecord, backgroundContext: self.managedObjectContext)
        }
        
        fetchRecordZoneChangesoperation.recordWithIDWasDeletedBlock = {[unowned self] (recordID, someString) in
            print("What is this? ", someString)
            print("Record deleted:", recordID)
            // write this record deletion to memory
            self.coreDataHelper.deleteManagedObject(using: recordID, backgroundContext: self.managedObjectContext)
        }
        
        fetchRecordZoneChangesoperation.recordZoneChangeTokensUpdatedBlock = { (zoneID, token, data) in
            // Flush record changes and deletions for this zone to disk
            DispatchQueue.main.async {
                try! self.managedObjectContext.save()
            }
            
            // Write this new zone change token to disk
            guard let changeToken: CKServerChangeToken = token else { return }
            let zoneKey =  self.zoneKeyPrefix + "\(zoneID.zoneName)"
            let data = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(data, forKey: zoneKey)
            UserDefaults.standard.synchronize()
            
        }
        
        fetchRecordZoneChangesoperation.recordZoneFetchCompletionBlock = {[unowned self] (zoneID, changeToken, _, _, error) in
            
            if let error = error as? CKError {
                let errorCode = error.errorCode
                os_log("Error on fetch record zone change with ErrorCode: %@", errorCode)
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                
                return
            }
            
            DispatchQueue.main.async {
                try! self.managedObjectContext.save()
            }
            
            
            
            // Write this new zone change token to disk
            guard let changeToken: CKServerChangeToken = changeToken else { return }
            let zoneKey =  self.zoneKeyPrefix + "\(zoneID.zoneName)"
            let data = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(data, forKey: zoneKey)
            UserDefaults.standard.synchronize()
            
        }
        
        fetchRecordZoneChangesoperation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                print("Inside fetch record zone changes operation")
            }
            print("We are good...")
            completion()
        }
        
        database.add(fetchRecordZoneChangesoperation)
    }

    // MARK: - General helper
    
    static func encodeMetadata(of cloudKitRecord: CKRecord) -> NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver.init(forWritingWith: data)
        coder.requiresSecureCoding = true
        cloudKitRecord.encodeSystemFields(with: coder)
        coder.finishEncoding()
        
        return data
    }
    
    static func decodeMetadata(from data: NSData) -> CKRecord {
        // setup the CKRecord with its metadata only
        let coder = NSKeyedUnarchiver(forReadingWith: data as Data)
        coder.requiresSecureCoding = true
        let record = CKRecord(coder: coder)!
        coder.finishDecoding()
        
        // now we have bare CKRecord with only Metadata
        // we need to add the custom fields to be useful 
        return record
    }
    
    private func retryCKOperation(of error: CKError, f: @escaping () -> Void) {
        if let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? Double {
            let delayTime = DispatchTime.now() + retryAfter
            DispatchQueue.global().asyncAfter(deadline: delayTime, execute: f)
        }
    }
    
    private func handlingCKOperationError(of error: Error, retryableFunction: @escaping () -> Void) {
        isRetryOperation = true
        if let error = error as? CKError {
            let errorCode = error.errorCode
            let cloudKitError = CloudKitError(rawValue: errorCode)!
            if cloudKitError.isFatalError() {
                os_log("We got fatal error: %@", cloudKitError.description)
            } else if cloudKitError.isRetryCase() {
                os_log("We got retryable ")
                isRetryOperation = true
                retryCKOperation(of: error, f: retryableFunction)
            } else {
                os_log("We got neither fatal nor retryable CKError: %@", cloudKitError.description)
            }
        } else {
            // Other error before reaching CK layer
            // e.g. Error Domain=NSCocoaErrorDomain Code=4097 "connection to service named com.apple.cloudd" UserInfo={NSDebugDescription=connection to service named com.apple.cloudd}
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2, qos: .background, flags: DispatchWorkItemFlags.detached, execute: {
                    retryableFunction()
            })
        }
    }
    
    //MARK: - To save localChanges in CoreData to CloudKit


    private func saveLocalChangesToCloudKit() {
        let recordsToSave = coreDataHelper.getRecordsToModify(backgroundContext: managedObjectContext)
        let recordIDsToDelete = coreDataHelper.getRecordIDsForDeletion(backgroundContext: managedObjectContext)
        
        saveToCloudKitOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        if !isRetryOperation {
            saveToCloudKitOperation.addDependency(fetchDatabaseChangesoperation)
        } else {
            isRetryOperation = false
        }
        
        saveToCloudKitOperation.isAtomic = true
        saveToCloudKitOperation.savePolicy = .changedKeys
        saveToCloudKitOperation.modifyRecordsCompletionBlock = {[unowned self] (modifiedCKRecords, deletedRecordIDs, error) in
            guard error == nil else {
                os_log("Error occured during save local change to CloudKit: %s", error!.localizedDescription)
                
                self.handlingCKOperationError(of: error!, retryableFunction: self.saveLocalChangesToCloudKit)
                return
            }
            
            self.coreDataHelper.postSuccessfyModifyOnCloudKit(modifiedCKRecords: modifiedCKRecords!, backgroundContext: self.managedObjectContext)
            self.coreDataHelper.postSuccessfulDeletionOnCloudKit(backgroundContext: self.managedObjectContext)
          //  group.leave()
        }
        privateDB.add(saveToCloudKitOperation)

    }
}














