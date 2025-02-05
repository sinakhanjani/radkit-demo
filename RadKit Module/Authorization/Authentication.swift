//
//  Authorization.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import Foundation

class Authentication {
    
    static let auth = Authentication()
    
    enum Platform: Int {
        case none, android, ios
    }
    
    let defaults = UserDefaults.standard
    
    private var _isLoggedIn: Bool {
        get {
            return defaults.bool(forKey: "IS_LOGGED_IN_KEY")
        }
        set {
            defaults.set(newValue, forKey: "IS_LOGGED_IN_KEY")
        }
    }

    private var _token: String {
        get {
            return defaults.value(forKey: "TOKEN_KEY") as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: "TOKEN_KEY")
        }
    }
    
    public var mobile: String {
        get {
            return defaults.value(forKey: "MOBILE_KEY") as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: "MOBILE_KEY")
        }
    }
    
    public var isLoggedIn: Bool {
        return _isLoggedIn
    }
    
    public var token: String {
        return _token
    }
    
    public func authenticationUser(token: String, isLoggedIn: Bool, mobile:String) {
        self._token = token
        self._isLoggedIn = isLoggedIn
        self.mobile = mobile
    }
    
    public func logOutAuth() {
        self._isLoggedIn = false
        self._token = ""
        self.mobile = ""
        let userInformation = UserInformation()
        DataManager.shared.userInformation = userInformation
    }
    
    
}
