//
//  AppDelegate.swift
//  Region
//
//  Created by Troy Stribling on 4/3/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(forTypes:UIUserNotificationType.Sound|UIUserNotificationType.Alert|UIUserNotificationType.Badge,
                categories:nil))
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        Notify.resetEventCount()
    }

    func applicationWillTerminate(application: UIApplication) {
    }


}

