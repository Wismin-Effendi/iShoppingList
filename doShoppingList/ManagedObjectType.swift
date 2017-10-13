//
//  ManagedObjectType.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation

protocol ManagedObjectType: class {
    static var entityName: String { get }
}
