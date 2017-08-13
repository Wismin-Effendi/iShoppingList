//
//  AppDelegate.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 7/22/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let coreDataStack = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList)
    let cloudKitHelper: CloudKitHelper = CloudKitHelper.sharedInstance
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        setupCloudKit()
        application.registerForRemoteNotifications()
        
        if let options: NSDictionary = launchOptions as NSDictionary? {
            let remoteNotification = options[UIApplicationLaunchOptionsKey.remoteNotification]
            
            if let notification = remoteNotification {
                self.application(application, didReceiveRemoteNotification: notification as! [AnyHashable : Any], fetchCompletionHandler: { (result) in
                    
                })
            }
        }
        
        guard let nc = self.window?.rootViewController as? UINavigationController else {
            fatalError("RootViewController not found")
        }
        
        guard let shoppingListTVC = nc.viewControllers.first as? ShoppingListTableViewController else {
            fatalError("ShoppingListTableViewController not found")
        }
        
        shoppingListTVC.coreDataStack = coreDataStack
        shoppingListTVC.managedObjectContext = coreDataStack.managedObjectContext
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        cloudKitHelper.saveLocalChangesToCloudKit()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        runTransferTodaysItemFromWarehouseToActiveGroceryItems()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveContext()
    }
    
    // MARK: - Receive Notification 
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        os_log("Receive notification")
        
        let dict = userInfo as! [String: NSObject]
        
        guard let notification: CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary: dict) as?
            CKDatabaseNotification else { return }
        
        cloudKitHelper.fetchChanges(in: notification.databaseScope) {
            os_log("inside completion handler for fetch changes")
            completionHandler(.newData)
        }
    }

    // MARK: - Private
    private func runTransferTodaysItemFromWarehouseToActiveGroceryItems() {
        coreDataStack.performBackgroundTask { (backgroundContext) in
            RepeatedItemsCoordinator.shared(backgroundContext: backgroundContext).transferTodayItemsToActiveGroceryItems()
        }
    }
    
    private func setupCloudKit() {
        // Zones compliance
        cloudKitHelper.setCustomZonesCompliance()
        
        // Fetch subscriptions
        cloudKitHelper.createDBSubscription()
        cloudKitHelper.fetchAllDatabaseSubscriptions()
    }
}

