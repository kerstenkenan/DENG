//
//  AppDelegate.swift
//  DENG
//
//  Created by Kersten Weise on 05.12.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var content = ContentModel()
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        let center = UNUserNotificationCenter.current()
//        center.delegate = self
//        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
//            if let err = err {
//                print("Granting user notification failed: \(err)")
//            } else {
//                print("User notification granted.")
//            }
//        }
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(#function)")
        switch application.applicationState {
        case .background:
            var badgeNumber = UserDefaults.standard.integer(forKey: "bagdeNumber")
            badgeNumber += 1
            application.applicationIconBadgeNumber = badgeNumber
            UserDefaults.standard.set(badgeNumber, forKey: "bagdeNumber")
        default: break
        }
        self.content.getVocab()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(#function)
        self.content.getVocab()
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(#function)
        self.content.getVocab()
        completionHandler()
    }
}
