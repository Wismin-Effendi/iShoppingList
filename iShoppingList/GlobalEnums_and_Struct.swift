//
//  GlobalEnums_and_Struct.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation

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
    static let GroceryItems = "GroceryItems"
    static let ShoppingList = "ShoppingList"
}

