//
//  DataManager.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit

class DataManager {
    
    static let shared = DataManager()
    
    public var userInformation: UserInformation? {
        get {
            return UserInformation.decode(directory: UserInformation.archiveURL)
        }
        set {
            if let encode = newValue {
                UserInformation.encode(userInfo: encode, directory: UserInformation.archiveURL)
            }
        }
    }
    
    public var applicationLanguage: Constant.Language = .fa {
        didSet {
            NotificationCenter.default.post(name: Constant.Notify.LanguageChangedNotify, object: nil)
        }
    }
    
    public var isMultiLanguage: Bool = false
}


enum Status {
    case success,failed,changedIP,deviceAdded
}

enum TypeRequest: Int {
    case directRequest = 1
    case timeRequest = 2
    case stateRequest = 3
    case lockRequest = 4
    case otherRequest = 6
    case scenarioRequest = 7
    case switchSenarioRequest = 8
    case updateTime = 9
    case otherRequest3 = 10
    case otherRequest4 = 11
    case updateDeviceInfo = 12
    case bossSenarioRequest = 13
    case bossRequest = 14
}

enum ParameterRequest: Int {
    case presnetRequest = 0
    case timeRequestList = 1
    case deviceParameter = 2
}

enum LockRequest: UInt {
    case open = 0
    case lock = 1
}

enum Req {
    case none
    case local
    case internet
}

enum ConnectionType {
    case mqtt
    case tcp
}

enum ThermostatType {
    case thermostat
    case fan
    case engine
    case humidity
}

enum DeviceType {
    case remotes
    case switch6
    //new
    case switch6_13
    case switch6_14
    case switch6_15
    //
    case switch12_0
    case switch12_1
    case switch12_2
    case switch12_3
    case switch1
    case switch12_sim_0
    case dimmer
    case rgbController
    case thermostat
    case engine
    case humidityControl
    case ac
    case tv
    case wifi
    case switchSenario
    case shortcut
    case inputStatus
    case cctv
    
    init?(rawValue: Int) {
        switch rawValue {
        case 3:
            self = .remotes
        case 1:
            self = .switch6
        case 2:
            self = .switch12_0
        case 7:
            self = .switch12_1
        case 8:
            self = .switch12_2
        case 10:
            self = .switch12_3
        case 11:
            self = .switch1
        case 12:
            self = .switch12_sim_0
        case 13: self = .switch6_13
        case 14: self = .switch6_14
        case 15:  self = .switch6_15
        case 4:
            self = .dimmer
        case 9:
            self = .rgbController
        case 5:
            self = .thermostat
        case 501: // internal fake code
            self = .ac // internal fake code
        case 502: // internal fake code
            self = .engine // internal fake code
        case 503: // internal fake code
            self = .humidityControl // internal fake code
        case 100:
            self = .tv
        case 99:
            self = .wifi
        case 401:
            self = .switchSenario
        case 9999:
            self = .shortcut
        case 9998:
            self = .inputStatus
        case 9997:
            self = .cctv
        default: return nil
        }
    }
    
    static var allCases: [DeviceType] {
        [.remotes, .switch6, .switch12_0, .switch12_1, .switch12_2, .switch12_3, .switch1, .switch12_sim_0, .dimmer, .rgbController, .thermostat, .tv, .wifi, .switchSenario, .ac, .engine, .humidityControl, .shortcut, .inputStatus, .cctv]
    }
    
    var rawValue: Int {
        switch self {
        case .remotes:
            return 03
        case .switch6:
            return 01
        case .switch12_0:
            return 02
        case .switch12_1:
            return 07
        case .switch12_2:
            return 08
        case .switch12_3:
            return 10
        case .switch1:
            return 11
        case .switch12_sim_0:
            return 12
        case .dimmer:
            return 04
        case .rgbController:
            return 09
        case .thermostat:
            return 05
        case .tv:
            return 100
        case .wifi:
            return 99
        case .switchSenario:
            return 401
        case .ac:
            return 501 // internal fake code
        case .engine:
            return 502 // internal fake code
        case .humidityControl:
            return 503 // internal fake code
        case .switch6_13:
            return 13
        case .switch6_14:
            return 14
        case .switch6_15:
            return 15
        case .shortcut:
            return 9999
        case .inputStatus:
            return 9998
        case .cctv:
            return 9997
        }
    }

    func changed() -> String {
        switch self {
        case .remotes:
            return "Remote-"
        case .switch1:
            return "1ch-"
        case .switch6:
            return "6ch-"
        case .switch12_0:
            return "12ch-"
        case .switch12_1:
            return "12ch-"
        case .switch12_2:
            return "12ch-"
        case .switch12_3:
            return "12ch-"
        case .switch12_sim_0:
            return "G12ch-"
        case .dimmer:
            return "DMR-"
        case .rgbController:
            return "RGB-"
        case .thermostat:
            return "TRM-"
        case .tv:
            return "TV"
        case .wifi:
            return "Wireless"
        case .switchSenario:
            return "SC"
        case .ac:
            return "Fan Coil"
        case .engine:
            return "Boiler"
        case .humidityControl:
            return "Humidity Control"
        case .switch6_13:
            return "6ch-"
        case .switch6_14:
            return "6ch-"
        case .switch6_15:
            return "6ch-"
        case .shortcut:
            return "Shortcut-"
        case .inputStatus:
            return "Input/Status"
        case .cctv:
            return "CCTV"
        }
    }
    
    func channelCount() -> Int {
        switch self {
        case .remotes:
            return 0
        case .switch1:
            return 1
        case .switch6:
            return 6
        case .switch12_0:
            return 12
        case .switch12_1:
            return 12
        case .switch12_2:
            return 12
        case .switch12_3:
            return 12
        case .switch12_sim_0:
            return 12
        case .dimmer:
            return 6
        case .rgbController:
            return 2
        case .thermostat:
            return 5
        case .tv:
            return 0
        case .wifi:
            return 0
        case .switchSenario:
            return 0
        case .ac:
            return 2
        case .engine:
            return 1
        case .humidityControl:
            return 1
        case .switch6_13:
            return 2
        case .switch6_14:
            return 3
        case .switch6_15:
            return 4
        case .shortcut:
            return 0
        case .inputStatus:
            return 16
        case .cctv:
            return 1
        }
    }
    
    func imagename() -> String {
        switch self {
        case .remotes:
            return "material_remote"
        case .switch1:
            return "material_switch"
        case .switch6:
            return "material_switch"
        case .switch12_0:
            return "material_switch"
        case .switch12_1:
            return "material_switch"
        case .switch12_2:
            return "material_switch"
        case .switch12_3:
            return "material_switch"
        case .switch12_sim_0:
            return "material_switch"
        case .dimmer:
            return "material_dimmer"
        case .rgbController:
            return "material_RGB"
        case .thermostat:
            return "material_thermostat"
        case .tv:
            return "material_tv"
        case .wifi:
            return "wifi_remote"
        case .switchSenario:
            return "sc_sw"
        case .ac:
            return "ac"
        case .engine:
            return "boiler"
        case .humidityControl:
            return "hum"
        case .switch6_13:
            return "13"
        case .switch6_14:
            return "14"
        case .switch6_15:
            return "15"
        case .shortcut:
            return "d22"
        case .inputStatus:
            return "9998"
        case .cctv:
            return "CCTV"
        }
    }
}

enum thermostatMode:Int {
    case warm = 0
    case cold = 1
    case off = 2
    case on = 3
}
