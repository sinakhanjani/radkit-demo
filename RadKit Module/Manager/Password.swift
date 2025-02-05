//
//  Password.swift
//  RadKit Module
//
//  Created by Sina khanjani on 11/1/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import Foundation

class Password {
    static let shared = Password()
    
    let defaults = UserDefaults.standard

    private var _currentPassword: String? {
        get {
            return defaults.value(forKey: "currentPassword") as? String
        }
        set {
            defaults.set(newValue, forKey: "currentPassword")
        }
    }

    var currentPassword: String? {
        get {
            _currentPassword
        }
        set {
            _currentPassword = newValue
        }
    }
    
    public var adminMode: Bool {
        get {
            return defaults.bool(forKey: "adminMode")
        }
        set {
            defaults.set(newValue, forKey: "adminMode")
        }
    }
    
    public var adminBackupModel: Bool {
        get {
            return defaults.bool(forKey: "adminBackupModel")
        }
        set {
            defaults.set(newValue, forKey: "adminBackupModel")
        }
    }
}

@objc protocol ConfigAdminRolles: class {
    // Code
    @objc func adminChanged()
}

extension ConfigAdminRolles where Self: UIViewController {
    internal func adminAccess() {
        self.admin()
        NotificationCenter.default.addObserver(self, selector: #selector(ConfigAdminRolles.adminChanged), name: Constant.Notify.adminAccess, object: nil)
    }
    
     func admin() {
        if !Password.shared.adminMode {
            self.navigationItem.rightBarButtonItems?.forEach({ (barButtonitem) in
                barButtonitem.isEnabled = false
            })
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItems?.forEach({ (barButtonitem) in
                barButtonitem.isEnabled = true
            })
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}

