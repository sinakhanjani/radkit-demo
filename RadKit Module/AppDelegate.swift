//
//  AppDelegate.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/2/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//

import UIKit
import CoreData
import SystemConfiguration.CaptiveNetwork
import UserNotifications
import Firebase
import FirebaseMessaging
import ProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    static var fcmToken: String = ""
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ProgressHUD.animationType = .systemActivityIndicator
        let container = NSPersistentContainer(name: "RadKit_Module")
        container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                print("unresolved error \(error), \(error.userInfo)")
            }
        }
        //
        CoreDataStack.shared.storeContainer = container
        // fetch all devices
        CoreDataStack.shared.fetchDatabase()
        // UDP2 - for check device change ip when app started
        UDPBroadcast.instance.UDPBroadcast2 { (status,_) in
//            print("UDP2 Status: \(status)")
        }
        
        PresentManager.shared.firtOpen = true
        
        ESP_NetUtil.tryOpenNetworkPermission()
        EspTouchManager.shared.configureEspTouch()

        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.persianFont(size: 10)], for: .normal)

        if #available(iOS 13.0, *) {
            // In iOS 13 setup is done in SceneDelegate
        } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            self.window = window
            let mainstoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewcontroller:UIViewController = mainstoryboard.instantiateViewController(withIdentifier: "LoaderViewController") as! LoaderViewController
            window.rootViewController = newViewcontroller
            self.window?.makeKeyAndVisible()
        }
        // notification
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        application.applicationIconBadgeNumber = 0
        setupPushNotification(application)
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        NWSocketConnection.instance.dc()
        CoreDataStack.shared.saveContext()
    }
    
    // Sockets
    static func reluanchApplication() {
        CoreDataStack.shared.fetchDatabase()
        if !UserDefaults.standard.bool(forKey: "is_begin_in_app") {
            Password.shared.adminMode = true
            _ = CoreDataStack.shared.addRoomInDatabase(roomImage: UIImage.init(named: "home_back")?.jpegData(compressionQuality: 0.2), roomName: "Hall")
            _ = CoreDataStack.shared.addRoomInDatabase(roomImage: UIImage.init(named: "home_back")?.jpegData(compressionQuality: 0.2), roomName: "Kitchen")
            _ = CoreDataStack.shared.addRoomInDatabase(roomImage: UIImage.init(named: "home_back")?.jpegData(compressionQuality: 0.2), roomName: "Bedroom")
            UserDefaults.standard.set(true, forKey: "is_begin_in_app")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            if let devices = CoreDataStack.shared.devices {
                NWSocketConnection.instance.startApplication(devices: devices)
            }
        }
    }
    
    // Notification
    func setupPushNotification(_ application: UIApplication) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        application.registerForRemoteNotifications()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Registration Token: \(fcmToken ?? "")")
        AppDelegate.fcmToken = fcmToken ?? ""
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String.init(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        print("Push Notification Token: \(token)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let state = application.applicationState
        print(userInfo,state)
         completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
         // Print full message.
         print(userInfo)
        completionHandler()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

    }
    
    // MARK: Topics ----
    func addtoTopic(to: String) {
        Messaging.messaging().subscribe(toTopic: to) { (err) in
//            print("Subscribed to \(to) topic")
        }
    }
    
    func removetoTopic(from: String) {
        Messaging.messaging().unsubscribe(fromTopic: from) { (err) in
            if err == nil {
//                print("Unsubscribe to \(from) topic")
            }
        }
    }
}


//                    CoreDataStack.shared.addRadkitModule(internetToken: "111111", localToken: "111111", username: "857679", password: "698713", port: 27005, serial: 126524, type: 04, url: "postman.cloudmqtt.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "222222", localToken: "222222", username: "856221", password: "697255", port: 21277, serial: 127982, type: 09, url: "postman.cloudmqtt.com", version: 1, ip: "192.168.1.206", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "KEKNJN", localToken: "keDEEJ", username: "857150", password: "698184", port: 23174, serial: 127053, type: 05, url: "postman.cloudmqtt.com", version: 1, ip: "92.168.1.210", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "333333", localToken: "333333", username: "856046", password: "697080", port: 100, serial: 128157, type: 09, url: "www.google.com", version: 1, ip: "2.179.202.61", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "111333", localToken: "311133", username: "856046", password: "85858", port: 100, serial: 111111, type: 10, url: "www.google.com", version: 1, ip: "2.179.202.61", wifibssid: "NOT", escape: nil) // FAKE* 12-Ch
//                    CoreDataStack.shared.addRadkitModule(internetToken: "444444", localToken: "444444", username: "855759", password: "696793", port: 22199, serial: 128444, type: 03, url: "s1.imaxbms.com", version: 1, ip: "192.168.1.43", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "444444", localToken: "444444", username: "847412", password: "688446", port: 22199, serial: 136791, type: 03, url: "s1.imaxbms.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "UFCHKF", localToken: "ufJMKO", username: "853299", password: "694333", port: 22199, serial: 130904, type: 01, url: "s1.imaxbms.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "UFCHKF", localToken: "ufJMKO", username: "853299", password: "694333", port: 22199, serial: 130904, type: 02, url: "s1.imaxbms.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)
//                                CoreDataStack.shared.addRadkitModule(internetToken: "123456", localToken: "123456", username: "846024", password: "687058", port: 22199, serial: 138179, type: 11, url: "s1.imaxbms.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)
//        CoreDataStack.shared.addRadkitModule(internetToken: "123456", localToken: "123456", username: "846024", password: "687058", port: 22199, serial: 138179, type: 6, url: "s1.imaxbms.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)

        //            //// FAKE ::::
//                    CoreDataStack.shared.addRadkitModule(internetToken: "111111", localToken: "2212", username: "857679", password: "698713", port: 27005, serial: 126524, type: 04, url: "postman.cloudmqtt.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)
//                    CoreDataStack.shared.addRadkitModule(internetToken: "111111", localToken: "111111", username: "857679", password: "698713", port: 27005, serial: 127712, type: 04, url: "postman.cloudmqtt.com", version: 1, ip: "192.168.1.240", wifibssid: "NOT", escape: nil)


/*
 AppleID:
 Gmail:
 ibmsdeveloper@gmail.com
 Aa12831454
 
 ibmsdeveloper@gmail.com
 Md20212021
 */
