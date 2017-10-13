//
//  ChangeToken+CoreDataProperties.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/3/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import CoreData


extension ChangeToken {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChangeToken> {
        return NSFetchRequest<ChangeToken>(entityName: "ChangeToken")
    }

    @NSManaged public var previousServerChangeToken: NSObject

}
