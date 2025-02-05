//
//  SenarioConnection.swift
//  Master
//
//  Created by Sina khanjani on 11/12/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import Foundation

enum Week:String {
    case shanbe = "Saturday"
    case shanbe1 = "Sunday"
    case shanbe2 = "Monday"
    case shanbe3 = "Tuesday"
    case shanbe4 = "Wednesday"
    case shanbe5 = "Thursday"
    case jome = "Friday"
}

class SenarioConnection {
    static let instance = SenarioConnection()
    static var warningVC: UIViewController?

    public func runSenario(viewController:UIViewController,senario: Senario,completion: ((_ senarioRunType: SenarioRunType) -> Void)?) {
        SenarioSendDataController.runSenario(viewController: viewController, senario) { (type) in
            completion?(type)
        }
    }
    
    public func sendBusSenario(viewController:UIViewController,senario:Senario,selectedItem:BusInputViewController.SelectedItem, dict: [Int64 : [UInt8]], bridgeDevice: Device) {
        //go
        var send = [UInt8]()
        
        let senarioNumber = UInt8(selectedItem.channel)
        let deviceCount = UInt8(dict.count)
        
        send.append(senarioNumber)
        send.append(deviceCount)
        
        for (key,value) in dict {
            if let device = CoreDataStack.shared.devices?.first(where: { d in
                d.serial == key
            }) {
                // data
                var commandData = value
                commandData.removeFirst() // remove 0
                
                // add tedad ejra if needed
                let reapetedTime = senario.repeatedTime
                if reapetedTime != 0 {
                    commandData.append(UInt8(reapetedTime))
                }
                
                var serial = "\(device.serial)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                let deviceSerial: [UInt8] = Array(serial.utf8)
                let deviceType = device.isBossDevice ? UInt8(Int(device.type)+50):UInt8(Int(device.type))
                
                var data = deviceSerial
                data.append(deviceType)
                data.append(contentsOf: commandData)
                
                send.append(contentsOf: data)
            }
        }
        
        // condition ro remote universal
        let type = DeviceType.init(rawValue: Int(bridgeDevice.type))!
        
        switch type {
        case .tv,.remotes,.wifi:
            SenarioConnection.warningVC = OneActionAlertViewController.create2(viewController: viewController, device: bridgeDevice, isFromSenario: true)
        default: break
        }
        
        // send to device
        NWSocketConnection.instance.send(device: bridgeDevice, typeRequest: .bossSenarioRequest, data: send) { (bytes, device) in
//            guard let bytes = bytes, let device = device else { return }
//            var serial = "\(device.serial)"
//
//            if serial.count < 6 {
//                while serial.count < 6 {
//                    serial = "0" + serial
//                }
//            }
//
//            let type = DeviceType.init(rawValue: Int(device.type))!
//
//            switch type {
//            case .tv,.remotes,.wifi:
//                if bytes.count > 1 {
//                    DispatchQueue.main.async {
//                        SenarioConnection.warningVC?.dismiss(animated: true, completion: {
//                            viewController.presentIOSAlertWarning(message: "Assigned to external channel \(Int (bytes[1])) device \(serial)") {
//                                SenarioConnection.warningVC = nil
//                            }
//                        })
//                    }
//                }
//            default:
//                let msg = "Bus scenario \(selectedItem.name.lowercased())" + " " + "assigned to" + " " + "device \(serial)" + "" + "."
//                DispatchQueue.main.async {
//                    viewController.presentIOSAlertWarning(message: msg) {}
//                }
//            }
        }
    }
    
    public func sendSenarioToDevice(viewController:UIViewController,senario:Senario,selectedItem:ModuleInputViewController.SelectedItem, runTimesCount: Int? = nil) {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        var data: [UInt8] = [UInt8(selectedItem.channel),UInt8(commands.count)]
        for (index,command) in commands.enumerated() {
            let dd = command.sendData!
            var parameter:[UInt8] = []
            parameter.append(contentsOf: dd)
            if runTimesCount != nil { // halate jadid
                parameter.append(UInt8(radkitTime(time: command.time)))
            } else {
                if commands.count-1 == index {
                    parameter.append(UInt8(0))  // code zaman dastoor akhar 0 ersal shavad (halate qadim)
                } else {
                    parameter.append(UInt8(radkitTime(time: command.time)))
                }
            }
            data.append(contentsOf: parameter)
        }
        
        // add tedad ejra faqat vase halate jadid
        if let runTimesCount = runTimesCount, runTimesCount != 0 {
            data.append(UInt8(runTimesCount))
        }
        
        let serial = commands[0].deviceSerial
        guard let devices = CoreDataStack.shared.devices else { return }
        let index = devices.lastIndex { (dat) -> Bool in
            if dat.serial == Int64(serial) {
                return true
            }
            return false
        }
        guard let i = index else { return }
        let device = devices[i]
        
        NWSocketConnection.instance.send(device: device, typeRequest: .scenarioRequest, data: data) { (bytes, device) in
//            guard let _ = bytes, let device = device else { return }
//            var serial = "\(device.serial)"
//            if serial.count < 6 {
//                while serial.count < 6 {
//                    serial = "0" + serial
//                }
//            }
//            
//            let msg = "Assigned to external scenario \(selectedItem.row) in device \(serial)"
//            
//            DispatchQueue.main.async {
//                viewController.presentIOSAlertWarning(message: msg) {}
//            }
        }
    }
    
    public func sendSenarioToDeviceRemote(viewController:UIViewController,senario:Senario,channel:Int, runTimesCount: Int? = nil) {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        var data: [UInt8] = [UInt8(channel),UInt8(commands.count)]
        for (index,command) in commands.enumerated() {
            let dd = command.sendData!
            var parameter:[UInt8] = []
            parameter.append(contentsOf: dd)
            
            if let runTimesCount = runTimesCount { // halate jadid
                parameter.append(UInt8(radkitTime(time: command.time)))
                if runTimesCount != 0 {
                    parameter.append(UInt8(runTimesCount))
                }
            } else {
                if commands.count-1 == index {
                    parameter.append(UInt8(0))  // code zaman dastoor akhar 0 ersal shavad  (halate qadim)
                } else {
                    parameter.append(UInt8(radkitTime(time: command.time)))
                }
            }
            data.append(contentsOf: parameter)
        }
        
        let serial = commands[0].deviceSerial
        guard let devices = CoreDataStack.shared.devices else { return }
        let index = devices.lastIndex { (dat) -> Bool in
            if dat.serial == Int64(serial) {
                return true
            }
            return false
        }
        guard let i = index else { return }
        let device = devices[i]
        
        SenarioConnection.warningVC = OneActionAlertViewController.create2(viewController: viewController, device: device, isFromSenario: true)
        
        NWSocketConnection.instance.send(device: device, typeRequest: .scenarioRequest, data: data) { (bytes, device) in
//            guard let bytes = bytes, let device = device else { return }
//            var serial = "\(device.serial)"
//            if serial.count < 6 {
//                while serial.count < 6 {
//                    serial = "0" + serial
//                }
//            }
//            
//            DispatchQueue.main.async {
//                SenarioConnection.warningVC?.dismiss(animated: true) {
//                    viewController.presentIOSAlertWarning(message: "Assigned to external script number \(Int (bytes [1])) device \(serial)") {
//                        SenarioConnection.warningVC = nil
//                    }
//                }
//            }
        }
    }
    public func sendSenarioToDeviceRemote03(viewController:UIViewController,device:Device,channel:Int) {
        let data: [UInt8] = [UInt8(channel),UInt8(0)]
        SenarioConnection.warningVC = OneActionAlertViewController.create2(viewController: viewController, device: device, isFromSenario: true)
        NWSocketConnection.instance.send(device: device, typeRequest: .scenarioRequest,data: data) { (bytes, device) in
//            guard let bytes = bytes, let device = device else { return }
//            var serial = "\(device.serial)"
//            if serial.count < 6 {
//                while serial.count < 6 {
//                    serial = "0" + serial
//                }
//            }
//            
//            DispatchQueue.main.async {
//                SenarioConnection.warningVC?.dismiss(animated: true) {
//                    viewController.presentIOSAlertWarning(message:"Assigned to event script number \(Int (bytes [1])) device \(serial)") {
//                        SenarioConnection.warningVC = nil
//                    }
//                }
//            }
        }
    }
    private func radkitTime(time:Double) -> Int {
        if time >= 0.5 && time <= 20 {
            return Int(time*2)
        }
        if time >= 21.0 && time <= 59 {
            return Int(time+20.0)
        }
        if time >= 60.0 && time <= 300.0 {
            switch time {
            case 60.0:
                return 80
            case 120.0:
                return 81
            case 180:
                return 82
            case 240:
                return 83
            case 300:
                return 84
            default:
                return 1000
            }
        }
        if time >= 60.0 && time <= 300.0 {
            switch time {
            case 60.0:
                return 80
            case 120.0:
                return 81
            case 180:
                return 82
            case 240:
                return 83
            case 300:
                return 84
            default:
                return 1000
            }
        }
        if time>=600 && time <= (60*60.0) {
            switch time {
            case 600.0:
                return 89
            case (15*60.0):
                return 94
            case (20*60.0):
                return 99
            case (30*60.0):
                return 109
            case (40*60.0):
                return 119
            case (50*60.0):
                return 129
            case (60*60):
                return 139
            default:
                return 0
            }
        }
        return 1000
    }
    
    public func createWeekly(vc: UIViewController,recievedByte:[UInt8]?,device:Device?,hour:Int,minute:Int,day:[Int],name:String) {
        guard let recievedByte = recievedByte, let device = device else { return }
        var sendData = recievedByte
        let dayInt8 = bitsToByte(weeks: day)
        var nameInt8 = [UInt8](repeating: UInt8(0), count: 30)
        if let nameInBytes = name.data(using: .utf8)?.bytes {
            guard nameInBytes.count <= 30 else {
                vc.presentIOSAlertWarning(message: "Maximum name length is 15 characters.") {
                    //
                }
                return
            }
            for (index,byte) in nameInBytes.enumerated() {
                nameInt8[index] = byte
            }
        } else {
            vc.presentIOSAlertWarning(message: "Name is not valid") {
                //
            }
        }
        sendData.append(contentsOf: [UInt8(hour),UInt8(minute)]) // saat+daqiqeh
        sendData.append(dayInt8)// roze hafte
        sendData.append(contentsOf: nameInt8)

        NWSocketConnection.instance.send(device: device, typeRequest: .timeRequest,data: sendData, results: nil)
        vc.dismiss(animated: true, completion: nil)
    }
    
    public func removeWeekly(code: UInt8,device:Device) {
        NWSocketConnection.instance.send(tag: 47,device: device, typeRequest: .timeRequest,data: [code]) { (bytes, device) in
            ////
        }
    }
    
    public func fetchWeeklyIn(device:Device,completion: ((_ weeklys: [Weekly]?) -> Void)?) {
        NWSocketConnection.instance.send(tag:49, device: device, typeRequest: .stateRequest,parameterRequest: .timeRequestList, results: nil)
    }
    
    private func dayByteToBit(byte:UInt8) -> [Int] {
        var intDays = [Int](repeating: 0, count: 8)
        let bits = Data.toBits(bytes: [byte])
        for (index,bit) in bits.enumerated() {
            if index < 8 {
                if bit == .one {
                    intDays[index] = 1
                }
            }
        }
        return intDays
    }
    
    private func bitsToByte(weeks:[Int]) -> UInt8 {
        var bits = [Data.Bit](repeating: .zero, count: 8)
        for (index,week) in weeks.enumerated() {
            if week == 1 {
                bits[index] = .one
            }
        }
        let byte0 = Data.bitsToBytes(bits: bits.reversed())[0]
        return byte0
    }
}


