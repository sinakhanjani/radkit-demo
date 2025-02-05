//
//  Constant.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit

class Constant {
    
    struct Notify {
        static let dismissIndicatorViewControllerNotify = Notification.Name("dismissIndicatorViewController")
        static let LanguageChangedNotify = Notification.Name("englishLanguageChangedNotify")
        static let sample = Notification.Name("sampleNotify")
        static let changedStates = Notification.Name("changedStatedNotify")
        static let loginState = Notification.Name("loginState")
        static let endState = Notification.Name("endState")
        static let startState = Notification.Name("startState")
        static let newDeviceAdded = Notification.Name("newDeviceAdded")
        static let endSenario = Notification.Name("endSenario")
        static let adminAccess = Notification.Name("adminAccess")
        static let updatePassword = Notification.Name("updatePassword")
    }
    
    struct Colors {
        static let blue = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        static let green = #colorLiteral(red: 0, green: 0.6947382092, blue: 0.6967663169, alpha: 1)
    }
    
    struct Fonts {
        static let fontOne = "IRANSans"
        static let fontTwo = "IRANSansMobileFaNum-Bold"
    }
    
    struct Google {
        static let api = "GOOGLE MAP API KEY"
    }
    
    enum Alert {
        case none, failed, success, json
    }
    
    enum Language {
        case fa, en
    }
}

