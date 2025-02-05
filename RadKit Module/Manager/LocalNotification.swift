////
////  LocalNotification.swift
////  Master
////
////  Created by Sinakhanjani on 10/27/1397 AP.
////  Copyright © 1397 iPersianDeveloper. All rights reserved.
////
//
//import Foundation
//import UserNotifications
//
//
//class LocalNotification {
//
//    static let shared = LocalNotification()
//
//    func sendNotification(message: String, title: String) {
//        let content = UNMutableNotificationContent()
//        let requestIdentifier = "Notification"
//        content.badge = 1
//        content.title = title
//        content.subtitle = ""
//        content.body = message
//        content.categoryIdentifier = "actionCategory"
//        content.sound = UNNotificationSound.default
//        //        let url = Bundle.main.url(forResource: "notificationImage", withExtension: ".jpg")
//        //        do {
//        //            let attachment = try? UNNotificationAttachment(identifier: requestIdentifier, url: url!, options: nil)
//        //            content.attachments = [attachment!]
//        //        }
//        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1.5, repeats: false)
//        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
//        UNUserNotificationCenter.current().add(request) { (error:Error?) in
//            if error != nil {
//                print(error?.localizedDescription as Any)
//            }
//            print("Notification Register Success")
//        }
//    }
//
//
//}

