//
//  CloudKitHelpersScratchPad.swift
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
    case recordZeroID
}

enum CustomCKError: Error {
    case fetchZoneError(Error)
    case createZoneError(Error)
}

enum ICloudDBState {
    case unknown
    case new
    case persist
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
    
    let zoneID: CKRecordZoneID = CKRecordZoneID(zoneName: CloudKitZone.iShoppingList, ownerName: CKCurrentUserDefaultName)
    
    var icloudDBState: ICloudDBState = .unknown
    
    
    // we need to keep the reference for NSOperations around, so we use properties as their references
    var fetchRecordZoneOperation: CKFetchRecordZonesOperation?
    
    // and here are the fetchResultsValues 
    var recordZeroResult: CKRecord? = nil {
        didSet {
            if recordZeroResult != nil && recordZeroResult!["customZoneName"] as! String == CloudKitZone.iShoppingList {
                icloudDBState = .persist
            } else {
                icloudDBState = .new
            }
        }
    }
    
    var fetchRecordZoneResultDict : [CKRecordZoneID : CKRecordZone]? = nil {
        didSet {
            if fetchRecordZoneResultDict != nil {
                icloudDBState = .persist
            } else {
                icloudDBState = .new
            }
        }
    }
    
    // Singleton
    static var sharedInstance = CloudKitHelper()
    
    private init() {
        
        confirmCustomZoneAndSubscriptions()
        
    }
    
    /// Don't forget to call  synchronize()  on UserDefaults after update / set 
    
    func confirmCustomZoneAndSubscriptions() {
        
        // default to `false` when there is no userDefaults for the key
        var createdCustomZone = UserDefaults.standard.bool(forKey: CloudKitUserDefaults.createdCustomzone.rawValue)
        var subscribedToPrivateChanges = UserDefaults.standard.bool(forKey: CloudKitUserDefaults.subscribedToPrivateChanges.rawValue)
        var subscribedToSharedChanges = UserDefaults.standard.bool(forKey: CloudKitUserDefaults.subscribedToSharedChanges.rawValue)
        var recordZeroID: CKRecordID?

        if let data = UserDefaults.standard.object(forKey: CloudKitUserDefaults.recordZeroID.rawValue) as? Data {
            recordZeroID = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKRecordID
        }
        
        if let recordZeroID = recordZeroID {
            // let's fetch the record from default zone
            privateDB.fetch(withRecordID: recordZeroID, completionHandler: {[weak self] (record, error) in
                guard let strongSelf = self else { return }
                if error != nil {
                    fatalError("Please handle me at fetchRecordZero: \(error.debugDescription)")
                }
                strongSelf.recordZeroResult = record
            })
        } else {
            icloudDBState = .new
        }
        
        func checkForCustomRecordZone() -> Bool {
            guard createdCustomZone == true else {
                return false
            }
            
            let fetchRecordZoneOperation = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
            var result = false
            fetchRecordZoneOperation.fetchRecordZonesCompletionBlock = { [weak self] recordZoneDict, error in
                guard let strongSelf = self else { return }
                
                guard error == nil else {
                    fatalError("Error during fetch record zone. \(error.debugDescription)")
                    return
                }
                if recordZoneDict?[strongSelf.zoneID] != nil {
                    result = true
                }
            }
            return result
        }
        
        // create custom zone if not exists
        func createCustomZoneIfNecessary() throws {
            let createdZoneGroup = DispatchGroup()
            
            if !createdCustomZone {
                createdZoneGroup.enter()
                
                let customZone = CKRecordZone(zoneID: zoneID)
                
                let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])
                createZoneOperation.modifyRecordZonesCompletionBlock = { [weak self] (saved, deleted, error) in
                    guard let strongSelf = self else { return }
                    if (error == nil) {
                       createdCustomZone = true
                        UserDefaults.standard.set(createdCustomZone, forKey: CloudKitUserDefaults.createdCustomzone.rawValue)
                    } else {
                        os_log("Error during create CK custom zone.")
                    }
                    createdZoneGroup.leave()
                }
                createZoneOperation.qualityOfService = .userInitiated
                self.privateDB.add(createZoneOperation)
            }
        }
    }
    
    private func getSavedRecordID(key: String) {
        
    }
    
    // 





    
    
    
    
    // create subscription if not exists
    


}
