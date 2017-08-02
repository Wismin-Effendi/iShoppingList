//
//  ShoppingList+CoreDataClass.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/28/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc(ShoppingList)
public class ShoppingList: NSManagedObject {

}

extension ShoppingList {
    convenience init(using cloudKitRecord: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        self.identifier = cloudKitRecord.recordID.recordName
        update(using: cloudKitRecord)
    }
    
    func update(using cloudKitRecord: CKRecord) {
        self.title = cloudKitRecord.object(forKey: "title") as! String
        self.needsUpload = false
        self.modificationDate = NSDate()
    }
}
