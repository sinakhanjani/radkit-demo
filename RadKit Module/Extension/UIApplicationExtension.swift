//
//  UIApplicationExtension.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/16/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import UIKit

extension UIApplication {
    static var appVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String }
    static var appBuild: String { Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String }
    static var deviceID: String { UIDevice.current.identifierForVendor?.uuidString ?? "" }
    static var deviceType: String { UIDevice().model }
    
    static func set(root viewController: UIViewController) {
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
}
