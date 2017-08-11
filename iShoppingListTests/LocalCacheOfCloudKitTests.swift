//
//  LocalCacheOfCloudKitTests.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 8/10/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import XCTest
import CloudKit
import os.log

@testable import iShoppingList

class LocalCacheOfCloudKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    

    func testCheckZonesExist() {
        let ckHelper = CloudKitHelper.sharedInstance
       // let zoneExist = ckHelper.checkForCustomRecordZone()
       // XCTAssertTrue(zoneExist)
       ckHelper.checkAllCustomZone()
    }
    
    
}
