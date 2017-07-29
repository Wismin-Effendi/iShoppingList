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

    func setDefaultValues() {
        self.synced = false
        self.completed = false
        self.hasReminder =  false
        self.pendingDeletion = false
        self.archived =  false
        self.isRepeatedItem = false
        self.repetitionInterval = 0
        self.lastCompletionDate = self.lastCompletionDate ?? Date(timeIntervalSinceReferenceDate: 0) as NSDate
        self.reminderDate = self.reminderDate ?? Date(timeIntervalSinceReferenceDate: 0) as NSDate
        self.completionDate = self.completionDate ?? Date(timeIntervalSinceReferenceDate: 0) as NSDate
    }
}
