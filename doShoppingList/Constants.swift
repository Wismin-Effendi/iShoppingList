//
//  Constants.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 10/10/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation

enum AddItem: String {
    case shoppingList = "ShoppingList"
    case groceryItem = "GroceryItem"
    
    enum Attribute : String  {
        case staticText = "StaticText"
        case placeHolder = "Placeholder"
    }
}

let AddItemAttributeText: [String: [String: String]] = [
    "ShoppingList" : ["StaticText" : "Enter Store Name", "Placeholder" : "Enter New Store Name"],
    "GroceryItem"  : ["StaticText" : "Enter Grocery Item", "Placeholder" : "Enter New Grocery Item"]
]

enum CellIdentifier: String {
    case shoppingList = "ShoppingListTableViewCell"
    case groceryItem = "GroceryItemsTableViewCell"
}


enum NibName: String {
    case shoppingListCell = "ShoppingListViewCell"
}


public struct Constant {
    public static let MaxFreeVersionTask: Int = 20
    public static let DelayBeforeRefetchAfterUpload: Double = 2
    public static let NumRetryForError4097: Int = 0
    public static let DelayForRetryError4097: Double = 10
}


extension UserDefaults {
    public struct Keys {
        public static let lastSync = "lastSync"
        public static let nonCKError4097RetryToken = "nonCKError4097RetryToken"
    }
}
