//
//  PresentManager.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import Foundation

class PresentManager {
    
    static let shared = PresentManager()
    
    private let defaults = UserDefaults.standard
    
    public var isPresentRegistration: Bool {
        get {
            return defaults.bool(forKey: "PRESENT_REGISTER_VC_KEY")
        }
        set {
            defaults.set(newValue, forKey: "PRESENT_REGISTER_VC_KEY")
        }
    }
    
    public var isPresentWalkTrought: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "PRESENT_PAGE_VIEW_CONTROLLER_KEY")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "PRESENT_PAGE_VIEW_CONTROLLER_KEY")
        }
    }
    
    var firtOpen = false
}
