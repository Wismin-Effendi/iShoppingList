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
import CoreData
import os.log


class CloudKitService {
    
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    let recordZoneID: CKRecordZoneID
    var userRecordID: CKRecordID?
    
    static var sharedInstance = CloudKitService()
    
    private init() {
        privateDatabase = container().privateCloudDatabase
        
        let recordZone = CKRecordZone(zoneName: CloudKitZone.iShoppingList)
        let recordZoneID = recordZone.zoneID
        self.recordZoneID = recordZoneID
        
        container().fetchUserRecordID {[weak self] (recordID, error) in
            guard error == nil else {
                os_log("User not logged in to iCloud, need to show alert with button to URL of UIApplicationOpenSettingsURLString")
                return
            }
            self?.userRecordID = recordID
        }
        
        // any CloudKit action will pending/ignored until we have userRecordID !!!!
    }
    
    func startCloudKitSyncProcess() {
        guard let userRecordID = self.userRecordID else { return }
        
        let coreDataStack = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList)
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        
       
        func recordFetchBlockClosureShoppingList(_ record: CKRecord) {
            // attempt to retrieve the record by recordID.recordName as identity in Core Data so we could update later
            
            guard let coreDataShoppingList = CoreDataUtil.getShoppingListOf(storeIdentifier: record.recordID.recordName, moc: backgroundContext) else {
                
                // this is valid for case of new data from CloudKit.
                CoreDataUtil.createNewShoppingListRecord(fromCloudKitRecord: record) { error in
                    if error != nil {
                        os_log("We failed to create new record in core data")
                        fatalError("Failed to create new core data record")
                    }
                }
                return
            }
            // We are going to update the core data record here.
            
            // make sure we don't have needsUpload = true on the core data record. Else, show alert that
            // we are going to override with data from CloudKit
            if coreDataShoppingList.needsUpload == true {
                // we have conflict here, need to show warning that we will override.
                os_log("Replace me with proper alert that show override...")
                // but we are in background mode and no access to ViewController, maybe just append any alert during sync to
                // some LocalNotification that only run once,  or to some persistence store that will be read after sync process ended.
                // we could continue..
            }
            
            CoreDataUtil.updateCoreDataShoppingListRecord(coreDataShoppingList, using: record) { error in
                if error != nil {
                    os_log("We failed to update record in core data")
                    fatalError("Failed to update core data record")
                }
            }
        }

        func recordFetchBlockClosureGroceryItems(_ record: CKRecord) {
            // attempt to retrieve the record by recordID.recordName as identity in Core Data so we could update later
            
            guard let coreDataGroceryItem = CoreDataUtil.getGroceryItem(identifier: record.recordID.recordName, moc: backgroundContext) else {
                
                // this is valid case of new data from CloudKit.
                CoreDataUtil.createNewGroceryItemRecord(fromCloudKitRecord: record) { error in
                    if error != nil {
                        os_log("We failed to create new record in core data")
                        fatalError("Failed to create new core data record")
                    }
                }
                return
            }
            // We are going to update the core data record here.
            
            // make sure we don't have needsUpload = true on the core data record. Else, show alert that
            // we are going to override with data from CloudKit
            if coreDataGroceryItem.needsUpload == true {
                // we have conflict here, need to show warning that we will override.
                os_log("Replace me with proper alert that show override...")
                // but we are in background mode and no access to ViewController, maybe just append any alert during sync to
                // some LocalNotification that only run once,  or to some persistence store that will be read after sync process ended.
                // we could continue..
            }
            
            CoreDataUtil.updateCoreDataGroceryItemRecord(coreDataGroceryItem, using: record) { error in
                if error != nil {
                    os_log("We failed to update record in core data")
                    fatalError("Failed to update core data record")
                }
            }
        }
        
        func runQueryCKRecordsOperation() {
            
            let predicate: NSPredicate
            
            // first check if lastSync exist if not create first query without it.
            let userDefaults = UserDefaults.standard
            if let lastSync = userDefaults.object(forKey: UserDefaultsKey.lastSync) as? NSDate {
                
                // create query to iCloud based on lastSync and userRecordID
                predicate = NSPredicate(format: "modificationDate >= %@ AND lastModifiedUserRecordID != %@", lastSync, userRecordID)
                
                // update lastSync to current
                let currentSyncTime = NSDate()
                userDefaults.set(currentSyncTime, forKey: UserDefaultsKey.lastSync)
                // need to figure out if all succeed then we could set `lastSuccessfulSync`. Else we need to find out
                // how to get back to not yet successful updates and run them next time.
                
            }
            else {
                // probably first run, need to create the lastSync and save to UserDefaults
                predicate = NSPredicate(format: "TRUEPREDICATE")
            }
            
            // first process the ShoppingList then process the GroceryItems since GroceryItems has dependencies on ShoppingList
            // We need to make sure all ShoppingList sync successfully before continuing else we will have issue when working on GroceryItems.
            // any retry to CloudKit for ShoppoingList should finished successfully and only then could we strart the GroceryItems work.
            var recordType = EntityName.ShoppingList
            
            CloudKitUtil.queryCKRecordsOperation(recordType: recordType, recordZoneID: recordZoneID, predicate: predicate, recordFetchBlockClosure: recordFetchBlockClosureShoppingList) {
                os_log("Finished processing all records")
            }
            
            recordType = EntityName.GroceryItems
            
            CloudKitUtil.queryCKRecordsOperation(recordType: recordType, recordZoneID: recordZoneID, predicate: predicate, recordFetchBlockClosure: recordFetchBlockClosureShoppingList) {
                os_log("Finished processing all records")
            }
        }
        
        
        // Push deletion, update and create from local to remote
        
        func pushDeletionAtCoreDataToCloudKit() {

            let coreDataIDsPendingDeletion = CoreDataUtil.getIDsShoppingListPendingDeletion(moc: backgroundContext)
            let cloudKitCKRecordIDsToDelete = coreDataIDsPendingDeletion.map { (name) -> CKRecordID in
                CKRecordID(recordName: name, zoneID: recordZoneID)
            }
            CloudKitUtil.saveOrDeleteCKRecords(recordsToSave: nil, recordIDsToDelete: cloudKitCKRecordIDsToDelete)  { error in
                if error != nil {
                    os_log("Error: %@", error.debugDescription)
                    os_log("We need to handle the error here")
                }
                os_log("Done deletion on CloudKit")
            }
            // how to ensure we have handled all the temporary error of CloudKit and has perform the retry until successful???
            
            // if no error then delete from CoreData 
            coreDataIDsPendingDeletion.forEach { (identifier) in
                CoreDataUtil.deleteShoppingList(identifier: identifier, moc: backgroundContext)
            }
        }
        
        func pushCreateUpdateAtCoreDataToCloudKit() {
            
        }
        
    }
    
}
