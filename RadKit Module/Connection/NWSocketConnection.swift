//
//  NWSocketConnection.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/16/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import Foundation
import NetworkExtension
import SwiftMQTT
import Network

protocol NWSocketConnectionDelegate: AnyObject {
    func recievedItem(_ bytes: [UInt8]?,_ device: Device?, tag: Int, dict: Dictionary<String,Any>?)
}

class ConnectionModel {
    
    var tcp: TCPClientModel
    var mqtt: MQTTClientModel
    
    internal init(tcp: TCPClientModel, mqtt: MQTTClientModel) {
        self.tcp = tcp
        self.mqtt = mqtt
    }
}

class NWSocketConnection {
    static var instance = NWSocketConnection()
    
    weak var delegate: NWSocketConnectionDelegate?
    
    static var deviceConnections: [ConnectionModel] = []
    static var aliveTCPTimer: Timer?
    static var tryTCPConnectionTimer: Timer?
    
    func send(dict: Dictionary<String,Any>? = nil, tag: Int = 1111, device:Device, typeRequest: TypeRequest, data:[UInt8]?=nil, parameterRequest: ParameterRequest?=nil, lockRequest: LockRequest?=nil, request:Req?=nil, disableMQTT:Bool=false, results: ((_ bytes: [UInt8]?,_ device: Device?) -> Void)?) {
        
        var bridgeDevice: Device = device
        
        if device.isBossDevice {
            if let matchDevice = CoreDataStack.shared.devices?.first(where: { d in
                d.serial == device.bridgeDeviceSerial
            }) {
                bridgeDevice = matchDevice
            }
        }
        
        guard WebAPI.instance.reachability.connection != .none else {
            results?(nil,nil)
            return
        }
        guard let internetToken = bridgeDevice.internetToken, let localToken = bridgeDevice.localToken else {
            results?(nil,nil)
            return
        }
        
        if let deviceConnection = NWSocketConnection.deviceConnections.first(where: { $0.tcp.device.serial == bridgeDevice.serial}) {
            let token = deviceConnection.tcp.connectionType == "tcp" ? localToken:internetToken
            
            var send: [UInt8] = []
            // 0
            send = Array(token.utf8)
            // 1
            if device.isBossDevice {
                send.append(UInt8(TypeRequest.bossRequest.rawValue))
            } else {
                send.append(UInt8(typeRequest.rawValue))
            }
            
            if device.isBossDevice {
                //1
                var deviceSerialBytes = [UInt8]() //"\(device.serial)".asciiValuesString("\(device.serial)").data(using: .utf8)!.bytes // 49 48 48 49
                var serial = "\(device.serial)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                deviceSerialBytes = serial.asciiValues
                send.append(contentsOf: deviceSerialBytes)
                //2
                send.append(UInt8(Int(device.type+50)))
                //3
                send.append(UInt8(typeRequest.rawValue))
            }
            // 2
            if let value = parameterRequest {
                send.append(UInt8(value.rawValue))
            }
            // 3
            if let value = lockRequest {
                send.append(UInt8(value.rawValue))
            }
            // 4
            if let data = data {
                send.append(contentsOf: data)
            }
            // TCP
            if deviceConnection.tcp.connectionType == "tcp" {
                //                print("TCP SEND Serial \(device.serial)")
                guard let key = (deviceConnection.tcp.device.requestKey as Data?)?.bytes.first else {
                    results?(nil,nil)
                    return
                }
                let toModule = self.encryptByteByAdding(key: key, input: send)
                //                let device = deviceConnection.tcp.device
                
                deviceConnection.tcp.tag = tag
                deviceConnection.tcp.dict = dict
                deviceConnection.tcp.sendTCPData(toModule)
                deviceConnection.tcp.receiveTCPData { [weak self] didRead in
                    guard let self = self else { return }
                    deviceConnection.tcp.connectionType = "tcp"
                    let data = didRead
                    if let data = data {
                        if data.bytes.count == 1 {
                            print("---*--- WARNING KEY WARNING ---*---", data.bytes)
                            CoreDataStack.shared.devices?.first(where: { $0.serial == bridgeDevice.serial })?.requestKey = data
                            deviceConnection.tcp.device.requestKey = data
                            CoreDataStack.shared.saveContext()
                            results?(nil,nil)
                            return
                        }
                        guard let key = (deviceConnection.tcp.device.requestKey as Data?)?.bytes.first else {
                            results?(nil,nil)
                            return
                        }
                        
                        let tcpTag = deviceConnection.tcp.tag
                        let tcpDict = deviceConnection.tcp.dict
                        let tcpDevice = deviceConnection.tcp.device
                        let bytes = self.decryptByteBySubtracting(key: key, data: data.bytes)
                        
                        if let zeroByte = bytes.first {
                            if zeroByte == UInt8(TypeRequest.bossRequest.rawValue) {
                                var bossBytes = bytes
                                var bossDevice: Device?
                                if bossBytes.count>7 {
                                    let range = 0...7
                                    let snBytes = Array(bossBytes[1...6])
                                    let snData = Data(snBytes)
                                    if let snUtf8 = String(data: snData, encoding: .utf8) {
                                        bossDevice = CoreDataStack.shared.devices?.first(where: { dv in
                                            dv.serial == Int64(snUtf8)!
                                        })
                                    }
                                    
                                    bossBytes.removeSubrange(range)
                                }
                                
                                self.delegate?.recievedItem(bossBytes, bossDevice, tag: tcpTag, dict: tcpDict)
                                results?(bossBytes,bossDevice)
                                print("---*--- BUS", bossDevice?.serial, bossBytes)
                            } else {
                                self.delegate?.recievedItem(bytes, tcpDevice, tag: tcpTag, dict: tcpDict)
                                results?(bytes,tcpDevice)
                                print("---*--- GATEWAY",bridgeDevice.serial, bytes)
                            }
                        } else {
                            results?(nil,nil)
                        }
                    } else {
                        results?(nil,nil)
                    }
                }
                
                return // return from this scope
            }
            
            if !disableMQTT {
                // MQTT
                //                print("MQTT SEND Serial \(device.serial)")
                let publishTopic = "\(bridgeDevice.serial)/"
                let subscribeTopic = "\(bridgeDevice.serial)/"
                let nsdata = NSData(bytes: &send, length: send.count)
                let sendData = Data.init(referencing: nsdata)
                
                deviceConnection.mqtt.tag = tag
                deviceConnection.mqtt.dict = dict

                deviceConnection.mqtt.mqttSession?.publish(sendData, in: publishTopic, delivering: .atMostOnce, retain: false, completion: { (error) in
                    if error == .none {
                        //
                    } else {
                        results?(nil,nil)
                    }
                })
                deviceConnection.mqtt.mqttSession?.subscribe(to: subscribeTopic, delivering: .atMostOnce, completion: { (error) in
                    if error == .none {
                        
                    } else {
                        results?(nil,nil)
                    }
                })
                deviceConnection.mqtt.results = results
            }
        }
    }
    
    static func mqttSubscriber(dict: Dictionary<String,Any>? = nil, device:Device?, results: ((_ bytes: [UInt8]?,_ device: Device?) -> Void)?) {
        guard WebAPI.instance.reachability.connection != .none else {
            results?(nil,nil)
            return
        }
        guard let device = device else {
            results?(nil,nil)
            return
        }
        
        var bridgeDevice: Device?
        
        if device.isBossDevice {
            if let matchDevice = CoreDataStack.shared.devices?.first(where: { d in
                d.serial == device.bridgeDeviceSerial
            }) {
                bridgeDevice = matchDevice
            }
        }
        
        if let deviceConnection = NWSocketConnection.deviceConnections.first(where: { $0.mqtt.device.serial == bridgeDevice?.serial }) {
            if deviceConnection.tcp.device.connectionState == .none {
                return
            }
            // TCP
            if deviceConnection.tcp.device.connectionState == .wifi || deviceConnection.tcp.device.connectionState == .ipStatic {
                deviceConnection.tcp.dict = ["mqttSubscriber":"true"]
                
                deviceConnection.tcp.receiveTCPData { didRead in
                    deviceConnection.tcp.connectionType = "tcp"
                    let data = didRead
                    if let data = data {
                        if data.bytes.count == 1 {
                            print("---*--- WARNING KEY WARNING ---*---", data.bytes)
                            CoreDataStack.shared.devices?.first(where: { $0.serial == bridgeDevice?.serial })?.requestKey = data
                            deviceConnection.tcp.device.requestKey = data
                            CoreDataStack.shared.saveContext()
                            results?(nil,nil)
                            return
                        }
                        guard let key = (deviceConnection.tcp.device.requestKey as Data?)?.bytes.first else {
                            results?(nil,nil)
                            return
                        }
                        let bytes = NWSocketConnection.decryptByteBySubtracting(key: key, data: data.bytes)
                        if let zeroByte = bytes.first {
                            if zeroByte == UInt8(TypeRequest.bossRequest.rawValue) {
                                var bossBytes = bytes
                                var bossDevice: Device?
                                if bossBytes.count>7 {
                                    let range = 0...7
                                    let snBytes = Array(bossBytes[1...6])
                                    let snData = Data(snBytes)
                                    if let snUtf8 = String(data: snData, encoding: .utf8) {
                                        bossDevice = CoreDataStack.shared.devices?.first(where: { dv in
                                            dv.serial == Int64(snUtf8)!
                                        })
                                    }
                                    bossBytes.removeSubrange(range)
                                }
                                
                                let tcpDict = deviceConnection.tcp.dict
                                let tcpTag = deviceConnection.tcp.tag // 1111
                                
                                NWSocketConnection.instance.delegate?.recievedItem(bossBytes, bossDevice, tag: tcpTag, dict: tcpDict)
                                results?(bossBytes,bossDevice)
                                print("---*--- TCP/SUB BUS",bossDevice?.serial, bossBytes)
                            } else {
                                let tcpDict = deviceConnection.tcp.dict
                                let tcpTag = deviceConnection.tcp.tag // 1111
                                let tcpDevice = deviceConnection.tcp.device
                                
                                NWSocketConnection.instance.delegate?.recievedItem(bytes, bridgeDevice, tag: tcpTag, dict: tcpDict)
                                results?(bytes,tcpDevice)
                                print("---*--- TCP/SUB GATEWAY",tcpDevice.serial,bytes)
                            }
                        } else {
                            results?(nil,nil)
                        }
                    } else {
                        results?(nil,nil)
                    }
                }
                return
            }
            if deviceConnection.tcp.device.connectionState == .mqtt {
                //MQTT
                let subscribeTopic = "\(bridgeDevice!.serial)/app"
                //                deviceConnection.mqtt.tag = 1111
                deviceConnection.mqtt.dict = ["mqttSubscriber":"true"]

                deviceConnection.mqtt.mqttSession?.subscribe(to: subscribeTopic, delivering: .atMostOnce, completion: { (error) in
                    if error == .none {
                        //
                    } else {
                        results?(nil,nil)
                    }
                })
                deviceConnection.mqtt.results = results
                return
            }
        }
    }
    
    // AI
    func startApplication(devices: [Device]) {
        invalidateTimers()
        dc()
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
            guard let self = self else { return }
            // create connections
            var connections = [ConnectionModel]()
            // add connection to array
            devices.forEach { device in
                if !device.isBossDevice {
                    let connectionModel = self.startConnection(device: device)
                    connections.append(connectionModel)
                }
            }
            // get it to class
            NWSocketConnection.deviceConnections = connections
            // be alive tcp connection by sending message
            self.beAliveTCPConnectionEvery40Secend()
            self.tryToConnectLocalEvery10Second()
        }
    }
    
    func startConnection(device: Device) -> ConnectionModel {
        let tcp = TCPClientModel(device: device)
        tcp.setupSwiftTCPSocket(escapeTCP: nil)
        let mqtt = MQTTClientModel(device: device)
        mqtt.setupSwiftMQTTSocket(escapeMQTT: nil)
        
        return ConnectionModel(tcp: tcp, mqtt: mqtt)
    }
    
    // invalidate timers
    func invalidateTimers() {
        NWSocketConnection.aliveTCPTimer?.invalidate()
        NWSocketConnection.aliveTCPTimer = nil
        
        NWSocketConnection.tryTCPConnectionTimer?.invalidate()
        NWSocketConnection.tryTCPConnectionTimer = nil
    }
    
    //DC
    func dc() {
        for (index,_) in NWSocketConnection.deviceConnections.enumerated() {
            NWSocketConnection.deviceConnections[index].tcp.connection?.cancel()
            NWSocketConnection.deviceConnections[index].mqtt.mqttSession?.disconnect()
        }
    }
    
    // Find Connectiontype
    func connectionTypeFor(device: Device) -> ConnectionModel? {
        let serial = device.serial
        if device.isBossDevice {
            let connection = NWSocketConnection.deviceConnections.first { d in
                d.tcp.device.serial == device.bridgeDeviceSerial
            }
            
            return connection
        } else {
            let connection = NWSocketConnection.deviceConnections.filter({ $0.tcp.device.serial == serial }).first
            return connection
        }
    }
    
    // disable and remove one module
    func disableAndRemoveModule(device: Device) {
        if let index = NWSocketConnection.deviceConnections.lastIndex(where: { $0.mqtt.device.serial == device.serial }) {
            let deviceConnection = NWSocketConnection.deviceConnections[index]
            
            deviceConnection.tcp.connection?.cancel()
            deviceConnection.mqtt.mqttSession?.disconnect()
            
            NWSocketConnection.deviceConnections.remove(at: index)
        }
    }
}

extension NWSocketConnection {
    private func tryToConnectLocalEvery10Second() {
        NWSocketConnection.tryTCPConnectionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] (timer) in
            for deviceConnection in NWSocketConnection.deviceConnections {
                if (deviceConnection.tcp.device.connectionState != .wifi) && (deviceConnection.tcp.device.connectionState != .ipStatic) {
                    print("RUN EVERY 10 SECONDS \(deviceConnection.tcp.device.serial)")
                    if let state = deviceConnection.tcp.connection?.state {
                        switch state {
                        case .setup:
                            break
                        case .waiting(_):
                            deviceConnection.tcp.connection?.restart()
                        case .preparing:
                            break
                        case .ready:
                            break
                        case .failed(_):
                            let tcp = TCPClientModel(device: deviceConnection.tcp.device)
                            tcp.setupSwiftTCPSocket(escapeTCP: nil)
                            deviceConnection.tcp = tcp
                            break
                        case .cancelled:
                            break
                        @unknown default:
                            break
                        }
                    }
                    
                }
            }
        })
    }
    
    private func beAliveTCPConnectionEvery40Secend() {
        NWSocketConnection.aliveTCPTimer = Timer.scheduledTimer(withTimeInterval: 40.0, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            for deviceConnection in NWSocketConnection.deviceConnections {
                if deviceConnection.tcp.connectionType == "tcp" {
                    //                    print("#Be Alive Local Connection Serial: \(deviceConnection.tcp.device.serial)")
                    self.send(dict:["hearth":"hearth"], device: deviceConnection.tcp.device, typeRequest: .stateRequest, parameterRequest: .deviceParameter, results: nil)
                    print("BE ALIVE RESPONSE \(deviceConnection.tcp.device.serial)")
                }
            }
        })
    }
}

extension NWSocketConnection {
    private func hexBytes(data:Data) -> String {
        return data
            .map { String($0, radix: 16, uppercase: true) }
            .joined(separator: ", ")
    }
    
    private func encryptByte(input:String, key:UInt8) -> Data {
        var inputBytes: [UInt8] = Array(input.utf8).map { $0^key }
        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
        let data = Data.init(referencing: nsdata)
        return data
    }
    
    private func decryptByte(data:Data, key:UInt8) -> String? {
        let bytes = data.bytes
        let inputBytes: [UInt8] = bytes.map { $0^key }
        guard let utf8String = String.init(bytes: inputBytes, encoding: .utf8) else {
            return nil
        }
        return utf8String
    }
    
    private func encryptByteByAdding(key: UInt8, input:[UInt8]) -> Data {
        var send: [UInt8] = input.map { ($0^key).addingReportingOverflow(100).partialValue }
        let nsdata = NSData(bytes: &send, length: send.count)
        let data = Data.init(referencing: nsdata)
        
        return data
    }
    
    private func decryptByteBySubtracting(key: UInt8, data:[UInt8]) -> [UInt8] {
        let send = data.map { ($0.subtractingReportingOverflow(100).partialValue)^key }
        
        return send
    }
    
    public static func decryptByteBySubtracting(key: UInt8, data:[UInt8]) -> [UInt8] {
        let send = data.map { ($0.subtractingReportingOverflow(100).partialValue)^key }
        
        return send
    }
    
    public static func ToData(input:[Int]?) -> Data? {
        if let input = input {
            var send: [UInt8] = input.map { UInt8($0) }
            let nsdata = NSData(bytes: &send, length: send.count)
            let dataF = Data.init(referencing: nsdata)
            
            return dataF
        }
        
        return nil
    }
    
    public func toString(data:[UInt8]) -> String {
        var inputBytes: [UInt8] = data
        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
        let data = Data.init(referencing: nsdata)
        inputBytes = []
        return String.init(data: data, encoding: .utf8)!
    }
}

extension StringProtocol {
    var asciiValues: [UInt8] { compactMap(\.asciiValue) }
}
