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
    
    
    func testCreateOneGroceryItemThenCloneToWarehouseDeliverItemsToActiveGroceryItems() {
        let storeName = "Costco"
        let groceryItem = "Banana"
        
        CoreDataUtil.deleteAllGroceryItems(moc: moc)
        CoreDataUtil.deleteShoppingList(title: storeName, moc: moc)
        CoreDataUtil.createOneSampleShoppingList(title: storeName, moc: moc)
        
        CoreDataUtil.deleteGroceryItem(title: groceryItem, moc: moc)
        
        // set to one day for immediate delivery post cloning
        CoreDataUtil.createOneSampleGroceryItem(storeName: storeName, title: groceryItem, repetitionInterval: TimeIntervalConst.oneDay, moc: moc)
        
        let identifier = CoreDataUtil.getGroceryItemIdentifierFromTitle(title: groceryItem, moc: moc)!
        _ = CloneItemToWarehouse(identifier: identifier, moc: moc, completion: { print("completed cloning1") } )
        _ = CloneItemToWarehouse(identifier: identifier, moc: moc, completion: { print("completed cloning2") } )
        var count = CoreDataUtil.getWarehouseItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 1)
        
        let warehouseItem = CoreDataUtil.getWarehouseItem(title: groceryItem, moc: moc)!
        print(warehouseItem)
        
        RepeatedItemsCoordinator.shared(backgroundContext: moc).transferTodayItemsToActiveGroceryItems()
        count = CoreDataUtil.getWarehouseItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 0)
        
        // we delete the completed item after successful delivery, so count is 1 instead of 2
        count = CoreDataUtil.getGroceryItemsCount(title: groceryItem, moc: moc)
        XCTAssertEqual(count, 1)
        
    }
    
    
}
