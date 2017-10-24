//
//  UserNotificationHelper.swift
//  iShoppingList
//
//  Created by Wismin Effendi on 10/11/17.
//  Copyright © 2017 Cleancoder.ninja. All rights reserved.
//

import Foundation
import UserNotifications
import os.log

struct UserNotificationHelper {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [[.alert, .sound, .badge]]) { (granted, error) in
            if error != nil {
                os_log("Error when requesting notification %@", log: .default, type: .error, error.debugDescription)
            }
            if !granted {
                os_log("Permission for user notification was not granted", log: .default, type: .debug)
            }
        }
    }
    
    static func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: completionHandler)
    }
}
