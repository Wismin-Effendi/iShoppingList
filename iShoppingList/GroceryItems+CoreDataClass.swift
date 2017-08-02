//
//  GroceryItems+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(GroceryItems)
public class GroceryItems: NSManagedObject {
    
    func setDefaultValuesForLocalCreation() {
        self.needsUpload = true
        self.completed = false
        self.hasReminder =  false
        self.pendingDeletion = false
        self.archived =  false
        self.isRepeatedItem = false
        self.repetitionInterval = 0
        self.lastCompletionDate =  NSDate()
        self.reminderDate = NSDate()
        self.completionDate = NSDate()
        self.modificationDate = NSDate()
    }
    
    func setDefaultValuesForLocalChange() {
        self.modificationDate = NSDate()
        self.needsUpload = true
    }
    
    func setForLocalDeletion() {
        self.needsUpload = true
        self.pendingDeletion = true
        self.modificationDate = NSDate()
    }
    
    func setDefaultValuesForRemoteCreation() {
        self.needsUpload = false
        self.pendingDeletion = false
        self.archived = false
        self.modificationDate = NSDate()
    }
}

extension GroceryItems {
    
    convenience init(using cloudKitRecord: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        self.setDefaultValuesForRemoteCreation()
        self.identifier = cloudKitRecord.recordID.recordName
        update(using: cloudKitRecord)
    }
    
    func update(using cloudKitRecord: CKRecord) {
        self.completed = cloudKitRecord.object(forKey: "completed") as! Bool
        self.completionDate = (cloudKitRecord.object(forKey: "completionDate") as! NSDate)
        self.hasReminder = cloudKitRecord.object(forKey: "hasReminder") as! Bool
        self.isRepeatedItem = cloudKitRecord.object(forKey: "isRepeatedItem") as! Bool
        self.lastCompletionDate = (cloudKitRecord.object(forKey: "lastCompletionDate") as! NSDate)
        self.reminderDate = (cloudKitRecord.object(forKey: "reminderDate") as! NSDate)
        self.title = cloudKitRecord.object(forKey: "title") as! String
    }
}
