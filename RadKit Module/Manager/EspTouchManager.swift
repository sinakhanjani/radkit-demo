//
//  EspTouchManager.swift
//  Master
//
//  Created by Sina khanjani on 6/3/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

public class EspTouchManager {
    
    public static let shared = EspTouchManager()
    
    private let defaults = UserDefaults.standard

    private var _espTouchLogin: Bool {
        get {
            return defaults.bool(forKey: "espTouchLogin")
        }
        set {
            defaults.set(newValue, forKey: "espTouchLogin")
        }
    }
    
    public var espTouch_ssid: String {
        get {
            return defaults.value(forKey: "espTouch_ssid") as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: "espTouch_ssid")
        }
    }
    
    public var espTouch_bssid: String {
        get {
            return defaults.value(forKey: "espTouch_bssid") as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: "espTouch_bssid")
        }
    }
    
    public var espTouchLogin: Bool {
        return _espTouchLogin
    }
    
    public func configureEspTouch() {
        self.espTouch_ssid = fetchSsid()
        self.espTouch_bssid = fetchBssid()
        self._espTouchLogin = true
        print("ssid:\(espTouch_ssid)","bssid:\(espTouch_bssid)")
    }
    
    private func  fetchSsid() -> String {
        if let ssidInfo = fetchNetInfo() {
            return ssidInfo.value(forKey: "SSID") as! String
        }
        
        return "SSID"
    }
    
    public func fetchBssid() -> String {
        if let bssidInfo = fetchNetInfo() {
            return bssidInfo.value(forKey: "BSSID") as! String
        }
        
        return "SSID"
    }
    
    private func fetchNetInfo() -> NSDictionary? {
        if let interfaceNames: NSArray = CNCopySupportedInterfaces() {
            var SSIDInfo : NSDictionary?
            for interfaceName in interfaceNames {
                if let x =   CNCopyCurrentNetworkInfo(interfaceName as! CFString) {
                    SSIDInfo = x
                }
            }
            
            return SSIDInfo
        }

        return nil
    }
}
