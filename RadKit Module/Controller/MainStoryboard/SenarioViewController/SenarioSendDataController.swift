//
//  SenarioController.swift
//  Master
//
//  Created by Sina khanjani on 11/10/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import Foundation
import UIKit

enum SenarioRunType {
    case begin
    case last
    case enter(index:Int)
    case failed
}
enum SenarioType {
    case senario
    case weekly
}

class SenarioSendDataController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- SenarioSendData")
        //
    }
    
    enum Escape {
        case new
        case old
        case failed
        case update
    }
    private var senarioType: SenarioType
    
    init(senarioType: SenarioType) {
        self.senarioType = senarioType
    }
    
    struct Switch {
        static func sendData(deviceSerial:Int64?,data:[UInt8]) {
            guard let serial = deviceSerial else { return }
            guard let devices = CoreDataStack.shared.devices else { return }
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            guard let i = index else { return }
            let device = devices[i]

            NWSocketConnection.instance.send(device: device, typeRequest: .timeRequest,data: data) { (bytes, device) in
                if let device = device, let bytes = bytes {
                    print("weekly/Switch/",bytes,device.serial)
                }
            }
        }
    }
    
    struct Dimmer {
        static func sendData(deviceSerial:Int64?,data:[UInt8]) {
            guard let serial = deviceSerial else { return }
            guard let devices = CoreDataStack.shared.devices else { return }
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            guard let i = index else { return }
            let device = devices[i]

            NWSocketConnection.instance.send(device: device, typeRequest: .timeRequest, data: data) { (bytes, device) in
                guard let bytes = bytes, let device = device else { return }
                print("weekly/Dimmer/",bytes,device.serial)
            }
        }
    }
    
    struct RGBModule {
        static func sendData(deviceSerial:Int64?,data:[UInt8]) {
            guard let serial = deviceSerial else { return }
            guard let devices = CoreDataStack.shared.devices else { return }
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            guard let i = index else { return }
            let device = devices[i]

            NWSocketConnection.instance.send(device: device, typeRequest: .timeRequest, data: data) { (bytes, device) in
                guard let device = device, let bytes = bytes else { return }
                print("weekly/RGB/",bytes,device.serial)
            }
        }
    }
    
    struct Thermostat {
        static func sendData(deviceSerial:Int64?,data: [UInt8]) {
            guard let serial = deviceSerial else { return }
            guard let devices = CoreDataStack.shared.devices else { return }
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            guard let i = index else { return }
            let device = devices[i]

            sendDirectRequest(device: device, data: data) { (device, bytes) in
                guard let device = device, let bytes = bytes else { return }
                print("weekly/Thermostat/",bytes,device.serial)
            }
        }
        private static func sendDirectRequest(device: Device, data:[UInt8], completion: @escaping (_ device: Device?,_ bytes: [UInt8]?) -> Void) {
            NWSocketConnection.instance.send(device: device, typeRequest: .timeRequest,data: data) { (bytes, device) in
                if let device = device, let bytes = bytes {
                    completion(device,bytes)
                }
            }
        }
    }
    
    struct All {
        static func send(deviceSerial:Int64?,data:Data) {
            guard let serial = deviceSerial else { return }
            guard let devices = CoreDataStack.shared.devices else { return }
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            guard let i = index else { return }
            let device = devices[i]
     
            NWSocketConnection.instance.send(device: device, typeRequest: .directRequest, data: data.bytes) { (bytes, device) in
                guard let device = device, let bytes = bytes else { return }
                print("Senario/*/",bytes,device.serial,"/*")
            }
        }
    }
    
    public static func runSenario(viewController:UIViewController,_ senario: Senario,completion: ((_ senarioRunType: SenarioRunType) -> Void)?) {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        guard !commands.isEmpty else {
            viewController.presentIOSAlertWarning(message: "This scenario does not contain any commands") {}
            completion?(.failed)
            return
        }
        func runOn(timeInterval: Double,index:Int,completion: @escaping () -> Void) {
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (timer) in
                completion()
                timer.invalidate()
            })
        }
        var wholeTime:Double = 0.0
        for (index,command) in commands.enumerated() {
            if index==0 {
                // begin
                runOn(timeInterval: 0.0,index: index) {
                    All.send(deviceSerial: command.deviceSerial, data: command.sendData!)
                    print(command.deviceSerial,command.time,command.sendData!.bytes)
                    completion?(.begin)
                    if commands.count == 1 {
                        completion?(.last)
                    }
                }
            }
            if index>0 {
                //to end
                wholeTime+=commands[index-1].time
                runOn(timeInterval: wholeTime,index: index) {
                    All.send(deviceSerial: command.deviceSerial, data: command.sendData!)
                    print(command.deviceSerial,command.time,command.sendData!.bytes)
                    if index == commands.count-1 {
                        // last
                        completion?(.last)
                    } else {
                        // entered index
                        completion?(.enter(index: index))
                    }
                }
            }
        }
    }
    
    public static func iSAllCommandsSameDevice(senario: Senario) -> Bool {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        guard !commands.isEmpty else { return false }
        var result = false
        var serials: [Int64] = []
        commands.forEach { (command) in
            serials.append(command.deviceSerial)
        }
        if allEqualUsingLoop(array: serials) {
            result = true
        } else {
            result = false
        }
        if result {
            let type = DeviceType.init(rawValue: Int(commands[0].deviceType))!
            switch type {
            case .switch12_0,.switch12_1,.switch12_2,.switch12_3, .switch12_sim_0:
                result = true
            default:
                result = false
            }
        }
        return result
    }
    
    public static func iSAllCommandsSameDeviceRGBThermoAndDimmer(senario: Senario) -> Bool {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        guard !commands.isEmpty else { return false }
        var result = false
        var serials: [Int64] = []
        commands.forEach { (command) in
            serials.append(command.deviceSerial)
        }
        if allEqualUsingLoop(array: serials) {
            result = true
        } else {
            result = false
        }
        if result {
            let type = DeviceType.init(rawValue: Int(commands[0].deviceType))!
            switch type {
            case .rgbController,.thermostat,.dimmer:
                result = true
            default:
                result = false
            }
        }
        return result
    }
    public static func iSAllCommandsSameDeviceRemote(senario: Senario) -> Bool {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        guard !commands.isEmpty else { return false }
        var result = false
        var serials: [Int64] = []
        commands.forEach { (command) in
            serials.append(command.deviceSerial)
        }
        if allEqualUsingLoop(array: serials) {
            result = true
        } else {
            result = false
        }
        
        if result {
            let type = DeviceType.init(rawValue: Int(commands[0].deviceType))!
            switch type {
            case .tv,.remotes,.wifi:
                result = true
            default:
                result = false
            }
        }
        return result
    }
    
    public static func iSAllCommandsSameDeviceRemotes03(senario: Senario) -> Bool {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        guard !commands.isEmpty else { return false }
        var result = false
        var serials: [Int64] = []
        commands.forEach { (command) in
            serials.append(command.deviceSerial)
        }
        if allEqualUsingLoop(array: serials) {
            result = true
        } else {
            result = false
        }
        if result {
            let type = DeviceType.init(rawValue: Int(commands[0].deviceType))!
            switch type {
            case .remotes:
                result = true
            default:
                result = false
            }
        }
        return result
    }
    private static func allEqualUsingLoop<T : Equatable>(array : [T]) -> Bool {
        if let firstElem = array.first {
            for elem in array {
                if elem != firstElem {
                    return false
                }
            }
        }
        return true
    }
    
    public func presnetEquipmentInSenario(_ viewController:UIViewController,equipment: Equipment,senario:Senario?, command: Command?=nil, repeatedTime: Int,completion: @escaping (_ status: Escape) -> Void) {
        switch senarioType {
        case .senario:
            self.senario(viewController: viewController, equipment: equipment, senario: senario, command: command, repeatedTime: repeatedTime) { [weak self] status in
                guard let self = self else { return }
                completion(status)
            }
        case .weekly:
            break
        }
    }
    
    public func presnetEquipmentInWeekly(_ viewController:UIViewController,equipment: Equipment, completion: @escaping (_ data: [UInt8]?,_ device:Device?,_ eqRelay: EQRely?) -> Void) {
        switch senarioType {
        case .senario:
            break
        case .weekly:
            self.weekly(viewController: viewController, equipment: equipment) { [weak self] (bytes, serial,eqRelay) in
                guard let self = self else { return }
                guard let devices = CoreDataStack.shared.devices else {
                    print("BUG HRTR0")
                    completion(nil,nil,nil) ; return }
                let index = devices.lastIndex { (dat) -> Bool in
                    if dat.serial == serial {
                        return true
                    }
                    return false
                }
                guard let i = index else {
                    print("BUG HRTR1")
                    completion(nil,nil,nil) ; return }
                let device = devices[i]
//                print(bytes,device,eqRelay,"RESULT -1")
                completion(bytes,device,eqRelay)
            }
        }
    }
    
    private func senario(viewController:UIViewController,equipment: Equipment,senario:Senario?, command: Command?=nil, repeatedTime: Int,completion: @escaping (_ status: Escape) -> Void) {
        if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
            switch deviceType {
            case .switch6,.switch6_13,.switch6_14,.switch6_15,.switch12_0,.switch12_1,.switch12_2,.switch12_3,.switch1,.switch12_sim_0:
                SwitchViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, bytes) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(.failed) ; return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
//                    completion(.old)
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes!, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes!)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { senarioEncode in
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes!)
                                completion(.new)
                            }
                        }
                    }
                }
            case .rgbController:
                RGBViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, rgb, bytes) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
                    let data = NWSocketConnection.instance.dataRGBForSenario(items: bytes, isDimmer: false, rgb: rgb)
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: data, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: data)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { [weak self] senarioEncode in
                                guard let self = self else { return }
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: data)
                                completion(.new)
                            }
                        }
                    }
                }
            case .dimmer:
                DimmerViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, condition, bytes) in
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    guard let self = self else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
                    let data = NWSocketConnection.instance.dataRGBForSenario(items: bytes!, isDimmer: true, rgb: nil, isWithFirstThree: condition!)
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: data, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: data)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { senarioEncode in
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: data)
                                completion(.new)
                            }
                        }
                    }

                }
            case .thermostat:
                ThermostatViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, mode, tanzim, tafazol, channel) in
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    guard let self = self else { return }

                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
                    let bytes = [UInt8(channel!),UInt8(mode!.rawValue),UInt8(tanzim!),UInt8(tafazol!)]
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { [weak self] senarioEncode in
                                guard let self = self else { return }
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            case .ac:
                ACViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, bytes) in
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    guard let self = self else { return }
                    guard let bytes = bytes else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { [weak self] senarioEncode in
                                guard let self = self else { return }
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            case .humidityControl:
                HumViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, bytes) in
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    guard let self = self else { return }
                    guard let bytes = bytes else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { [weak self] senarioEncode in
                                guard let self = self else { return }
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            case .engine:
                EngineViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, bytes) in
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    guard let self = self else { return }
                    guard let bytes = bytes else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name!
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { senarioEncode in
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            case .tv:
                TvRemoteViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, items) in
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    guard let self = self else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name ?? ""
                    let bytes = items ?? [UInt8]()
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { senarioEncode in
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            case .remotes:
                CustomRemoteViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, items) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name ?? ""
                    let bytes = items ?? [UInt8]()
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { senarioEncode in
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            case .wifi:
                WifiRemoteViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, items,name) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(.failed); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let serial = eqDevice.serial
                    let type = eqDevice.type
                    let relayName = eqRelay.name ?? ""
                    let bytes = items ?? [UInt8]()
                    if let command = command {
                        CoreDataStack.shared.updateCommandTo(deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes, command: command)
                        completion(.update)
                    } else {
                        if let senario = senario {
                            CoreDataStack.shared.addCommandTo(senario: senario, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                            completion(.old)
                        } else {
                            _ = CoreDataStack.shared.addNewSenario(name: "", repeatedTime: repeatedTime) { [weak self] senarioEncode in
                                guard let self = self else { return }
                                guard let senarioEncode = senarioEncode else { return }
                                CoreDataStack.shared.addCommandTo(senario: senarioEncode, deviceSerial: serial, deviceType: type, deviceName: relayName, bytes: bytes)
                                completion(.new)
                            }
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    private func weekly(viewController:UIViewController,equipment: Equipment, completion: @escaping (_ sendData: [UInt8]?,_ deviceSerial:Int64?,_ eqRelay: EQRely?) -> Void) {
        if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
            switch deviceType {
            case .switch6,.switch6_13,.switch6_14,.switch6_15,.switch12_0,.switch12_1,.switch12_2,.switch12_3, .switch1, .switch12_sim_0:
                SwitchViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, bytes) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil) ; return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    completion(bytes!,eqDevice.serial,eqRelay) // etelati be joz 4 parameter akhar:saat+daqiqe+rozeFaal+name*
                }
            case .inputStatus:
                InputStatusViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, bytes) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil) ; return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    completion(bytes!,eqDevice.serial,eqRelay)
                }
            case .rgbController:
                RGBViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, rgb, bytes) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let sendData = NWSocketConnection.instance.dataRGBForWeekly(items: bytes, isDimmer: false, rgb: rgb)
                    completion(sendData,eqDevice.serial,eqRelay)
                }
            case .dimmer:
                DimmerViewController.create(viewController: viewController, equipment: equipment) { [weak self]  (eqRelay, condition, bytes) in
                    guard let self = self else { return }
                guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                guard let eqDevice = eqRelay.eqDevice else { return }
                    let sendData = NWSocketConnection.instance.dataRGBForWeekly(items: bytes!, isDimmer: true, rgb: nil, isWithFirstThree: condition!)
                    completion(sendData,eqDevice.serial,eqRelay)
                }
            case .thermostat:
                ThermostatViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, mode, tanzim, tafazol, channel) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let sendData = [UInt8(eqRelay.digit+1),UInt8(mode!.rawValue),UInt8(tanzim!),UInt8(tafazol!)]
                    completion(sendData,eqDevice.serial,eqRelay)
                }
            case .ac:
                ACViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, data) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    completion(data,eqDevice.serial,eqRelay)
                }
            case .humidityControl:
                HumViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, data) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    completion(data,eqDevice.serial,eqRelay)
                }
            case .engine:
                EngineViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay, data) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    completion(data,eqDevice.serial,eqRelay)
                }
            case .tv:
                TvRemoteViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay,items) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let sendData = items ?? [UInt8]()
                    completion(sendData,eqDevice.serial,eqRelay)
                }
            case .remotes:
                CustomRemoteViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay,items) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let sendData = items ?? [UInt8]()
                    completion(sendData,eqDevice.serial,eqRelay)
                }
            case .wifi:
                WifiRemoteViewController.create(viewController: viewController, equipment: equipment) { [weak self] (eqRelay,items,name) in
                    guard let self = self else { return }
                    guard let eqRelay = eqRelay else { completion(nil,nil,nil); return }
                    guard let eqDevice = eqRelay.eqDevice else { return }
                    let sendData = items ?? [UInt8]()
                    completion(sendData,eqDevice.serial,eqRelay)
                }
                default:
                break
            }
        }
    }
}

