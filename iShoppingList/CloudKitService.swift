//
//  CloudKitService.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/31/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CloudKit
import MobileCoreServices
import os.log


class CloudKitService {
    
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    var currentRecord: CKRecord?
    var recordZoneID: CKRecordZoneID?
    
    static var sharedInstance = CloudKitService()
    
    private init() {
        privateDatabase = container().privateCloudDatabase
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.object(forKey: UserDefaultsKey.iShoppingListZoneID) as? Data,
            let recordZoneID = NSKeyedUnarchiver.unarchiveObject(with: data) as? CKRecordZoneID {
            self.recordZoneID = recordZoneID
        }
        
        let recordZone = CKRecordZone(zoneName: CloudKitZone.iShoppingList)
        let recordZoneID = recordZone.zoneID
        self.recordZoneID = recordZoneID
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: recordZoneID)
        userDefaults.set(encodedData, forKey: UserDefaultsKey.iShoppingListZoneID)
        
        privateDatabase?.save(recordZone, completionHandler: { (recordZone, error) in
            if (error != nil) {
                os_log("Record Zone Error: %@", "Failed to create custom record zone.")
            } else {
                os_log("Saved record zone")
            }
        })
    }
}
