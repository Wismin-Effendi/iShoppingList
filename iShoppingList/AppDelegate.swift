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
import UserNotifications
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var controller: UIViewController?
    
    var notificationAuthorized: Bool?
    
    let coreDataStack = CoreDataStack.shared(modelName: CoreDataModel.iShoppingList)
    let cloudKitHelper: CloudKitHelper = CloudKitHelper.sharedInstance
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        guard let nc = self.window?.rootViewController as? UINavigationController else {
            fatalError("RootViewController not found")
        }
        
        guard let shoppingListTVC = nc.viewControllers.first as? ShoppingListTableViewController else {
            fatalError("ShoppingListTableViewController not found")
        }
        
        shoppingListTVC.coreDataStack = coreDataStack
        shoppingListTVC.managedObjectContext = coreDataStack.managedObjectContext
        shoppingListTVC.cloudKitHelper = cloudKitHelper
        
        // CloudKit stuff
        NotificationCenter.default.addObserver(self, selector: #selector(handleCKAccountChange(notification:)), name: .CKAccountChanged, object: nil)
        
        checkThenRunCloudKitSetup(application)
        
        setupUserNotification()
        return true
    }
    
    
    // MARK: - The rest of application life cycle

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        runTransferTodaysItemFromWarehouseToActiveGroceryItems()
        DispatchQueue.global(qos: .utility).async {[unowned self] in
            self.cloudKitHelper.syncToCloudKit {
                os_log("Sync to cloudKit at will enter foreground", log: .default, type: .debug)
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveContext()
    }
    
    
    // MARK: - Private helper
    private func runTransferTodaysItemFromWarehouseToActiveGroceryItems() {
        coreDataStack.performBackgroundTask { (backgroundContext) in
            RepeatedItemsCoordinator.shared(backgroundContext: backgroundContext).transferTodayItemsToActiveGroceryItems()
        }
    }
    
    @objc func handleCKAccountChange(notification: NSNotification) {
        checkThenRunCloudKitSetup()
    }
    
    private func checkThenRunCloudKitSetup(_ application: UIApplication? = nil) {
        self.cloudKitHelper.checkCKAccountStatus {[unowned self] (accountStatus) in
            switch accountStatus {
            case .available:
                self.setupCloudKit()
                DispatchQueue.main.async {
                    os_log("We have valid iCloud account....", log: .default, type: .debug)
                    application?.registerForRemoteNotifications()
                }
            default:
                self.controller?.showAlertWarning(message: "Sync feature require iCloud account")
            }
        }
    }
    
    private func setupCloudKit() {
        DispatchQueue.global(qos: .utility).async {[unowned self] in
            self.cloudKitHelper.setupCloudKit()
        }
    }
    
    private func setupUserNotification() {
        UserNotificationHelper.requestAuthorization()
        UNUserNotificationCenter.current().delegate = self
        
        let snoozeAction15 = UNNotificationAction(identifier: "SnoozeAction15", title: "Snooze 15 mins", options: [])
        let snoozeAction30 = UNNotificationAction(identifier: "SnoozeAction30", title: "Snooze 30 mins", options: [])
        let category = UNNotificationCategory(identifier: "OverdueItemCategory", actions: [snoozeAction15, snoozeAction30], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // MARK: - Helper 
    
    static func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}


// MARK: - LocalNotification
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // for forreground notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        func snoozeSetting(timeInterval: TimeInterval) {
            let identifier = response.notification.request.identifier
            let content = response.notification.request.content
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    os_log("Uh oh! We has an error in adding user notification", log: .default, type: .error, error.localizedDescription)
                }
            }
        }
        
        switch response.actionIdentifier {
        case "SnoozeAction15":
            snoozeSetting(timeInterval: (15*60))
        case "SnoozeAction30":
            snoozeSetting(timeInterval: (30*60))
        default: break
        }
        
        completionHandler()
    }
    
    func scheduleNotification(at date: Date, identifier: String, title: String, body: String) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, era: components.era, year: components.year, month: components.month, day: components.day, hour: components.hour, minute: components.minute, second: components.second)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "OverdueItemsCategory"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                os_log("Uh oh! We had an error when scheduling notification: %s", log: .default, type: .error, error.localizedDescription)
            }
        }
    }
}


// MARK: - Receive Remote Notification

extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        os_log("Registered for remote notification", log: .default, type: .debug)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        // Skip Code = 3010 "remote notification not supported in the simulator"
        guard (error as NSError).code != 3010 else { return }
        
        os_log("Remote notification registration failed: %@", log: .default, type: .error, error.localizedDescription)
        controller?.showAlertWarning(message: "Please login to iCloud for remote data sync.")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        os_log("Receive notification", log: .default, type: .debug)
        
        let dict = userInfo as! [String: NSObject]
        
        guard let notification: CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary: dict) as?
            CKDatabaseNotification else { return }
        
        DispatchQueue.global(qos: .utility).async {[unowned self] in
            self.cloudKitHelper.fetchChanges(in: notification.databaseScope) {
                os_log("inside completion handler for fetch changes", log: .default, type: .debug)
                completionHandler(.newData)
            }
        }
    }
}
