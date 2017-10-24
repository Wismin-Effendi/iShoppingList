//
//  Extensions.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension ShoppingList: ManagedObjectType {
    
    static var entityName: String {
        return "ShoppingList"
    }
}

extension GroceryItem: ManagedObjectType {
    
    static var entityName: String {
        return "GroceryItem"
    }
}

extension Date {
    
    func toString(dateFormat format: String = "MMM-dd yyyy HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}


extension UIViewController {
    
    func showAlertWarning(message: String) {
        let alert = UIAlertController.init(title: "Warning", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }
}
