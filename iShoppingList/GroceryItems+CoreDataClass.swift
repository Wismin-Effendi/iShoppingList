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
        self.uploaded = false
        self.isCompleted = false
        self.hasReminder = false
        self.pendingDeletion = false
        self.isArchived = false
        self.reminderDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
        self.completionDate = Date(timeIntervalSinceReferenceDate: 0) as NSDate
    }
}
