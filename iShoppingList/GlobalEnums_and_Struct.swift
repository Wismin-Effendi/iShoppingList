//
//  GlobalEnums_and_Struct.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudKitConvertible {
    var identifier: String { get }
    var pendingDeletion: Bool { get set }
}

struct TimeIntervalConst {
    static let oneDay: Double = 3600.0 * 24.0
    static let twoDays: Double = oneDay * 2.0
    static let threeDays: Double = oneDay * 3.0
    static let fourDays: Double = oneDay * 4.0
    static let oneWeek: Double = oneDay * 7.0
    static let twoWeeks: Double = oneWeek * 2.0
    static let fourWeeks: Double = oneWeek * 4.0
    static let oneMonth: Double = oneDay * 30.0
    static let twentySixMonths: Double = oneMonth * 26.0
}

enum ItemCategory: String {
    case todo = "To-Do"
    case completed = "Completed"
    
    static func byIndex(_ index:Int) -> ItemCategory {
        guard 0...1 ~= index else { return ItemCategory.todo }
        
        let allCategories = [todo, completed]
        return allCategories[index]
    }
}

struct EntityName {
    static let GroceryItem = "GroceryItem"
    static let ShoppingList = "ShoppingList"
}

enum ItemsFilter: String {
    case todo = "To Do"
    case completed = "Completed"
}

struct CoreDataModel {
    static let iShoppingList = "iShoppingList"
}

struct ckShoppingList {
    static let title = "title"
    static let identifier = "identifier"
    static let localUpdate = "localUpdate"
}

struct ckGroceryItem {
    static let title = "title"
    static let identifier = "identifier"
    static let localUpdate = "localUpdate"
    static let reminderDate = "reminderDate"
    static let completed = "completed"
    static let completionDate = "completionDate"
    static let hasReminder = "hasReminder"
    static let isRepeatedItem = "isRepeatedItem"
    static let lastCompletionDate = "lastCompletionDate"
    static let storeName = "storeName"
}

enum CloudKitZone: String {
    case iShoppingListZone
  //  case addMeZone
  //  case deleteMeZone
    
    func recordZoneID() -> CKRecordZoneID {
        return CKRecordZoneID(zoneName: self.rawValue , ownerName: CKCurrentUserDefaultName)
    }
    
    static let allCloudKitZoneNames = [
        CloudKitZone.iShoppingListZone.rawValue,
    //    CloudKitZone.addMeZone.rawValue,
    //    CloudKitZone.deleteMeZone.rawValue
    ]
}

enum RecordType: String {
    case ShoppingList
    case GroceryItem
    case WarehouseGroceryItems
}

struct UserDefaultsKey {
    static let lastSync = "lastSync"
    static let iShoppingListZoneID = "iShoppingListZoneID"
}
