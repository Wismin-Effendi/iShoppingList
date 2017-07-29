//
//  iShoppingListTests.swift
//  iShoppingListTests
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import XCTest
import CoreData

@testable import iShoppingList

class iShoppingListTests: XCTestCase {
    
    var moc: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        moc = getBackgroundContext()
    }
    
    private func getBackgroundContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.coreDataStack.newBackgroundContext()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateDeleteOneItemFromWareHouse() {
        let title = "Avocado"
        
        CoreDataUtil.createOneSampleItemInWarehouse(title: title, moc: moc)
        var warehouseCountForItem = CoreDataUtil.getWarehouseItemsCount(title: title, moc: moc)
        XCTAssertEqual(warehouseCountForItem, 1)
        
        CoreDataUtil.deleteItemFromWarehouse(title: title, moc: moc)
        warehouseCountForItem = CoreDataUtil.getWarehouseItemsCount(title: title, moc: moc)
        XCTAssertEqual(warehouseCountForItem, 0)
    }
    
    
    func testCreateDeleteMultipleItemFromWareHouse() {
        let title = "Bread"
        
        for _ in 1...3 {
            CoreDataUtil.createOneSampleItemInWarehouse(title: title, moc: moc)
        }
        var warehouseCountForItem = CoreDataUtil.getWarehouseItemsCount(title: title, moc: moc)
        XCTAssertEqual(warehouseCountForItem, 3)
        
        CoreDataUtil.deleteItemFromWarehouse(title: title, moc: moc)
        warehouseCountForItem = CoreDataUtil.getWarehouseItemsCount(title: title, moc: moc)
        XCTAssertEqual(warehouseCountForItem, 0)
    }
    
    
    func testCreateOneGroceryItemThenCloneToWarehouseAndDeleteBoth() {
        let storeName = "Costco"
        let groceryItem = "Banana"
        
        CoreDataUtil.deleteShoppingList(title: storeName, moc: moc)
        CoreDataUtil.createOneSampleShoppingList(title: storeName, moc: moc)
        
        CoreDataUtil.deleteGroceryItem(title: groceryItem, moc: moc)
        CoreDataUtil.createOneSampleGroceryItem(storeName: storeName, title: groceryItem, moc: moc)
        
        let identifier = CoreDataUtil.getGroceryItemIdentifierFromTitle(title: groceryItem, moc: moc)!
        _ = CloneItemToWarehouse(identifier: identifier, moc: moc, completion: { print("completed cloning1") } )
        _ = CloneItemToWarehouse(identifier: identifier, moc: moc, completion: { print("completed cloning2") } )
        var count = CoreDataUtil.getWarehouseItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 1)
        CoreDataUtil.deleteItemFromWarehouse(title: groceryItem, moc: moc)
        count = CoreDataUtil.getWarehouseItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 0)
        count = CoreDataUtil.getGroceryItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 1)
        CoreDataUtil.deleteGroceryItem(title: groceryItem, moc: moc)
        count = CoreDataUtil.getGroceryItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 0)
        
    }
    
    
}
