//
//  GlobalEnums_and_Struct.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/27/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation

enum ItemCategory: String {
    case todo = "To-Do"
    case completed = "Completed"
    
    static func byIndex(_ index:Int) -> ItemCategory {
        guard 0...1 ~= index else { return ItemCategory.todo }
        
        let allCategories = [todo, completed]
        return allCategories[index]
    }
}


