//
//  GroceryItems+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData

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
    }
}
