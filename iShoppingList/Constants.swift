//
//  Constants.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 10/10/17.
//  Copyright © 2017 iShinobi. All rights reserved.
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
