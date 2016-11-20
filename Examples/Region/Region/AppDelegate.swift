//
//  AppDelegate.swift
//  Region
//
//  Created by Troy Stribling on 4/3/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import FutureLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(types:[UIUserNotificationType.sound, UIUserNotificationType.alert, UIUserNotificationType.badge],
                categories:nil))
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Notify.resetEventCount()
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }


}

