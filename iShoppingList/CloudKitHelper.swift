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


// MARK: Currently we don't handle the situation where user deleted the iCloud data for the app.
//       we still keep the UserDefaults on disk with value 'true' 
//       Also if user remove and add back the app, the iCloud data still exist including the custom zone 
//       and subscriptions.  So what to do here ?  we should not keep them in disk disconnected from reality
//       instead we should fetchZoneIDs and fetchSubscriptions to find out.

// In order to detect iCloud being reinitialized or it's new, we save 'recordZero' with value: zoneName of the custom zone. 
// we tried to retrieved from iCloud default zone, it record found, means it's in persist state.
//  No need to create customZone and  Subscriptions again.
//  but if not exist, we will check for existence of recordZone, if exist we move on to normal flow.
//  If also not found, then we'll create new Record Zone and new Subscriptions.


class CloudKitHelper {
// Initializing Container 
    
    let container = CKContainer.default()
    let privateDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let sharedDB: CKDatabase = CKContainer.default().sharedCloudDatabase
    let privateSubscriptionID = "private-changes"
    let sharedSubscriptionID = "shared-changes"
    
    let zoneKeyPrefix = "token4Zone-"
    let createdZoneGroup = DispatchGroup()
    
    let zoneID: CKRecordZoneID = CloudKitZone.iShoppingListZone.recordZoneID()
    
    
    var databaseChangeToken: CKServerChangeToken? = nil
    
    // default to `false` when there is no userDefaults for the key
    var createdCustomZone = UserDefaults.standard.bool(forKey: CloudKitUserDefaults.createdCustomzone.rawValue) {
        didSet {
            UserDefaults.standard.set(createdCustomZone, forKey: CloudKitUserDefaults.createdCustomzone.rawValue)
        }
    }
    
    var subscribedToPrivateChanges = UserDefaults.standard.bool(forKey: CloudKitUserDefaults.subscribedToPrivateChanges.rawValue) {
        didSet {
            UserDefaults.standard.set(subscribedToSharedChanges, forKey: CloudKitUserDefaults.subscribedToPrivateChanges.rawValue)
        }
    }
    
    var subscribedToSharedChanges = UserDefaults.standard.bool(forKey: CloudKitUserDefaults.subscribedToSharedChanges.rawValue) {
        didSet {
            UserDefaults.standard.set(subscribedToSharedChanges, forKey: CloudKitUserDefaults.subscribedToSharedChanges.rawValue)
        }
    }
    
    
    // we need to keep the reference for NSOperations around, so we use properties as their references
    var fetchRecordZoneOperation: CKFetchRecordZonesOperation?
    
    // Singleton
    static var sharedInstance = CloudKitHelper()

    let backgroundContext: NSManagedObjectContext
    
    private init() {
        backgroundContext = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList).newBackgroundContext()
        
    }
    
    
    
    
    // MARK: Modify custom zone to match CloudKitZones enums
    // 
    // Helper:
    func getExistingZoneIDs() -> [CKRecordZoneID]? {
        let group = DispatchGroup()
        var existingZoneIDs = [CKRecordZoneID]()
        group.enter()
        let fetchAllZonesOperations = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        fetchAllZonesOperations.fetchRecordZonesCompletionBlock = { recordZoneDict, error in
            
            if let error = error as? CKError {
                
                os_log("Need to have proper error handling here..!!")
                
                switch error.errorCode {
                case CKError.internalError.rawValue:
                    print("Internal error. Fatal")
                case CKError.networkUnavailable.rawValue:
                    print("Network unavailable")
                case CKError.notAuthenticated.rawValue:
                    print("Detected as Not authenticated to iCloud....")
                default:
                    break
                }
                
                os_log("error code: %d", error.errorCode)
                fatalError("Error during fetch record zone. \(error.localizedDescription)")
            }
            
            existingZoneIDs = Array(recordZoneDict!.keys)
            os_log("Existing zones: %@", existingZoneIDs.map { $0.zoneName } )
            group.leave()
        }
        privateDB.add(fetchAllZonesOperations)
        
        let dispatchTimeoutResult = group.wait(timeout: DispatchTime.now() + 5)
        switch dispatchTimeoutResult {
        case .timedOut:
            os_log("timeout during fetchAllZoneOperation")
            return nil
        case .success:
            print("Finish fetchAllZoneOperation run!")
            return existingZoneIDs
        }
    }
    
    // main function
    func setCustomZonesCompliance() {
        // The following should run in strict order, use DispatchGroup and Wait to sync the process
        // 1. run fetch allZone (see helper func above) 

        // 2. create zonesToCreate and zonesToDelete
        func processServerRecordZone(existingZoneIDs: [CKRecordZoneID]) -> (recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete:[CKRecordZoneID]?) {
            
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
            
            return (recordZonesToSave: setZonesToCreate(), recordZoneIDsToDelete: setZoneIDstoDelete())
        }
        
        
        // 3. run modifyRecordZone operation to create and delete zone for compliance
        func modifyRecordZones(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZoneID]?) {
            let group = DispatchGroup()
            group.enter()
            let modifyRecordZonesOperation = CKModifyRecordZonesOperation(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
            modifyRecordZonesOperation.modifyRecordZonesCompletionBlock = { modifiedRecordZones, deletedRecordZoneIDs, error in
                
                os_log("--CKModifyRecordZonesOperation.modifyRecordZonesOperation")

                if let error = error as? CKError {
                    
                    os_log("Need to have proper error handling here..!!")

                    switch error.errorCode {
                    case CKError.internalError.rawValue:
                        print("Internal error. Fatal")
                    case CKError.networkUnavailable.rawValue:
                        print("Network unavailable")
                    case CKError.notAuthenticated.rawValue:
                        print("Detected as Not authenticated to iCloud....")
                    default:
                        break
                    }
                    
                    os_log("error code: %d", error.errorCode)
                    fatalError("Modify RecordZonesOperation failed: \(error.localizedDescription)")
                }
                
                if let modifiedRecordZones = modifiedRecordZones {
                    modifiedRecordZones.forEach { os_log("Added recordZone: %@", $0) }
                }
                
                if let deletedRecordZoneIDs = deletedRecordZoneIDs {
                    deletedRecordZoneIDs.forEach { os_log("Deleted zoneID: %@", $0) }
                }
                
                group.leave()
            }
            privateDB.add(modifyRecordZonesOperation)
            
            let dispatchTimeoutResult = group.wait(timeout: DispatchTime.now() + 5)
            switch dispatchTimeoutResult {
            case .timedOut:
                os_log("timeout during modifyRecordZonesOperation")
            case .success:
                print("Finish modifyRecordZonesOperation run!")
            }
        }
        
        if let existingZoneIDs = getExistingZoneIDs() {
            let (recordZonesToSave, recordZoneIDsToDelete) = processServerRecordZone(existingZoneIDs: existingZoneIDs)
            if  recordZonesToSave != nil || recordZoneIDsToDelete != nil {
                modifyRecordZones(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
            }
            createdCustomZone = true
        }
    }
    
    
    // MARK: Subcribing to Change Notification 
    func fetchAllDatabaseSubscriptions() {
        fetchDatabaseSubscriptions(database: privateDB)
        fetchDatabaseSubscriptions(database: sharedDB)
    }
    
    func fetchDatabaseSubscriptions(database: CKDatabase) {
        let group = DispatchGroup()
        group.enter()
        let fetchSubscriptionOperation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        fetchSubscriptionOperation.fetchSubscriptionCompletionBlock = { subscriptions, error in
            guard error == nil else {
                fatalError("Fetch subscription failed: \(error.debugDescription)")
            }
            
            let subscriptionIDs = Array(subscriptions!.keys)
            subscriptionIDs.forEach { os_log("Subscription ID: %@", $0) }
            group.leave()
        }
        database.add(fetchSubscriptionOperation)
        group.wait(timeout: DispatchTime.now() + 5)
    }
    
    // create subscription if not exists
    func createDBSubscription() {
        subscribedToPrivateChanges = false
        subscribedToSharedChanges = false

        let group = DispatchGroup()

        print("create private")
        group.enter()
        let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: privateSubscriptionID)
        createSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
            if error == nil { self.subscribedToPrivateChanges = true }
            else {
                fatalError("failed to create private subscription. \(error.debugDescription)")
            }
            group.leave()
        }
        privateDB.add(createSubscriptionOperation)
    
        print("create shared")
        group.enter()
        let createSharedSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: sharedSubscriptionID)
        createSharedSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
            if error == nil { self.subscribedToSharedChanges = true }
            else {
                fatalError("failed to create shared subscription. \(error.debugDescription)")
            }
            group.leave()
        }
        sharedDB.add(createSharedSubscriptionOperation)
        let result = group.wait(timeout: DispatchTime.now() + 5)
        switch result {
        case .timedOut:
            os_log("Timed out on shared")
        case .success:
            os_log("Success on shared")
        }
    }
    
    
    /// Don't forget to call  synchronize()  on UserDefaults after update / set
    
    func confirmChangeNotificationSubscriptions() {
        
        func fetchAllSubscriptions() {
            let group = DispatchGroup()
            let fetchSubscriptionOperation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
            group.enter()
            fetchSubscriptionOperation.fetchSubscriptionCompletionBlock = { subscriptions, error in
                guard error == nil else {
                    fatalError("Fetch subscription failed: \(error.debugDescription)")
                }
                
                let subscriptionIDs = Array(subscriptions!.keys)
                subscriptionIDs.forEach { os_log("Subscription ID: %@", $0) }
                group.leave()
            }
            privateDB.add(fetchSubscriptionOperation)
            group.wait(timeout: DispatchTime.now() + 5)
        }
        
        // create subscription if not exists
        func createDBSubscription() {
            createPrivateDBSubscription()
            createSharedDBSubscription()
        }
        
        func createPrivateDBSubscription() {
            if !subscribedToPrivateChanges {
                let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: privateSubscriptionID)
                
                createSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
                    if error == nil { self.subscribedToPrivateChanges = true }
                    else {
                        fatalError("failed to create private subscription. \(error.debugDescription)")
                    }
                }
                privateDB.add(createSubscriptionOperation)
            }
        }
        
        func createSharedDBSubscription() {
            if !subscribedToPrivateChanges {
                let createSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionID: sharedSubscriptionID)
                
                createSubscriptionOperation.modifySubscriptionsCompletionBlock = {[unowned self] (subscriptions, deletedIDs, error) in
                    if error == nil { self.subscribedToSharedChanges = true }
                    else {
                        fatalError("failed to create private subscription. \(error.debugDescription)")
                    }
                }
                privateDB.add(createSubscriptionOperation)
            }
        }
    
        func fetchOfflineServerChanges() {
            createdZoneGroup.notify(queue: DispatchQueue.global()) { [unowned self] in
                if self.createdCustomZone {
                    self.fetchChanges(in: .private) {}
                    self.fetchChanges(in: .public) {}
                }
            }
        }
    
    }
    
    func fetchOfflineServerChanges() {
        print(self.createdCustomZone)
        createdZoneGroup.notify(queue: DispatchQueue.global()) { [unowned self] in
            //if self.createdCustomZone {
                self.fetchChanges(in: .private) {}
            //   self.fetchChanges(in: .shared) {}
            // }
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
        
        let group = DispatchGroup()
        
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
        
        print("are we here..?")
        group.enter()
        
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // write this zone deletion to memory
        }
        
        operation.changeTokenUpdatedBlock = {[unowned self] (token) in
            // Flush zone deletion for this database to disk 
            // Write this new database change token to memory 
            
            self.databaseChangeToken = token
            
            let data = NSKeyedArchiver.archivedData(withRootObject: token)
            UserDefaults.standard.set(data, forKey: ServerChangeToken.DatabaseChangeToken.rawValue)
            UserDefaults.standard.synchronize()
        }
        
        
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                print("Error during fetch database changes operation", error)
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
                group.leave()
            }
            
        }
        print("are we here...?")
        database.add(operation)
        
        print("We just add the operation...")
        print("Should took some time..")
        
        let result = group.wait(timeout: DispatchTime.now() + 5)
        switch result {
        case .success:
            print("it is a success")
        case .timedOut:
            print("it is a timeout")
        }
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
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, optionsByRecordZoneID: optionsByRecordZoneID)
        
        operation.recordChangedBlock = {[unowned self] (ckRecord: CKRecord) in
            print("Record changed:", ckRecord)
            // Write this record change to memory 
            CoreDataHelper.sharedInstance.insertOrUpdateManagedObject(using: ckRecord, backgroundContext: self.backgroundContext)
        }
        
        operation.recordWithIDWasDeletedBlock = {[unowned self] (recordID, someString) in
            print("What is this? ", someString)
            print("Record deleted:", recordID)
            // write this record deletion to memory
            CoreDataHelper.sharedInstance.deleteManagedObject(using: recordID, backgroundContext: self.backgroundContext)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneID, token, data) in
            // Flush record changes and deletions for this zone to disk
            try! self.backgroundContext.save()
            
            // Write this new zone change token to disk
            guard let changeToken: CKServerChangeToken = token else { return }
            let zoneKey =  self.zoneKeyPrefix + "\(zoneID.zoneName)"
            let data = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(data, forKey: zoneKey)
            UserDefaults.standard.synchronize()
            
        }
        
        operation.recordZoneFetchCompletionBlock = {[unowned self] (zoneID, changeToken, _, _, error) in
            
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
                
                return
            }
            // Flush record changes and deletions for this zone to disk 
            try! self.backgroundContext.save()
            
            // Write this new zone change token to disk
            guard let changeToken: CKServerChangeToken = changeToken else { return }
            let zoneKey =  self.zoneKeyPrefix + "\(zoneID.zoneName)"
            let data = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(data, forKey: zoneKey)
            UserDefaults.standard.synchronize()
            
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                print("Error fetching zone changes for \(databaseTokenKey) database:", error)
            }
            print("We are good...")
            completion()
        }
        
        database.add(operation)
    }

    
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
    
    
    // Mark: - To save localChanges in CoreData to CloudKit
    
    func saveLocalChangesToCloudKit() {
        let group = DispatchGroup()
        let recordsToSave = CoreDataHelper.sharedInstance.getRecordsToModify(backgroundContext: backgroundContext)
        let recordIDsToDelete = CoreDataHelper.sharedInstance.getRecordIDsForDeletion(backgroundContext: backgroundContext)
        
        group.enter()
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        operation.isAtomic = true
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = {[unowned self] (modifiedCKRecords, deletedRecordIDs, error) in
            guard error == nil else {
                let error = error as! CKError
                os_log("Error code: %d", error.errorCode)
                os_log("Error dump: %@", error as CVarArg)
                fatalError("Failed to save localChange to CloudKit: \(error.localizedDescription)")
            }
            
            CoreDataHelper.sharedInstance.postSuccessfyModifyOnCloudKit(modifiedCKRecords: modifiedCKRecords!, backgroundContext: self.backgroundContext)
            CoreDataHelper.sharedInstance.postSuccessfulDeletionOnCloudKit(backgroundContext: self.backgroundContext)
            group.leave()
        }
        privateDB.add(operation)
        let result = group.wait(timeout: DispatchTime.now() + 5)
        switch result {
        case .success:
            os_log("Operation successful")
        case .timedOut:
            os_log("Operation timeout for saving to CloudKit")
        }
    }
}













