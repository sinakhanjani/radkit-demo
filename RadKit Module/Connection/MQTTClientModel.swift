//
//  MQTTClientModel.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/17/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import Foundation
import SwiftMQTT

class MQTTClientModel: NSObject {
    
    public var mqttSession: MQTTSession?
    
    public var device: Device
    public var tag = 1111
    public var dict: Dictionary<String,Any>?

    public var connectionType = "none"
    
    public var results: ((_ bytes: [UInt8]?, _ device: Device?) -> Void)?
    
    init(device: Device) {
        self.device = device
    }
    
    func setupSwiftMQTTSocket(escapeMQTT: ((_ bytes: [UInt8]?,_ device:Device?) -> Void)?) {
        guard let url = device.url, let username = device.username, let password = device.password else {
            escapeMQTT?(nil,nil)
            return
        }
        let host = url
        let port: UInt16 = UInt16(device.port)
        let clientID = self.clientID()
        mqttSession = MQTTSession(host: host, port: port, clientID: clientID, cleanSession: true, keepAlive: 10, useSSL: true)
        mqttSession?.delegate = self
        mqttSession?.username = username
        mqttSession?.password = password
        mqttSession?.connect { [weak self] error in
            guard let self = self else { return }
            if error == .none {
                print("mqtt is conntected to device serial : \(self.device.serial)")
                NWSocketConnection.instance.send(device: self.device, typeRequest: .stateRequest, parameterRequest: .deviceParameter, results: nil) // this is for check connection in now estable
            } else {
//                print("mqtt cannot be connected to device serial : \(self.device.serial)")
                escapeMQTT?(nil,nil)
            }
        }
    }
}

extension MQTTClientModel {
    private func clientID() -> String {
        let userDefaults = UserDefaults.standard
        let clientIDPersistenceKey = "clientID\(arc4random())\(arc4random())"
        let clientID: String
        
        if let savedClientID = userDefaults.object(forKey: clientIDPersistenceKey) as? String {
            clientID = savedClientID
        } else {
            clientID = randomStringWithLength(5)
            userDefaults.set(clientID, forKey: clientIDPersistenceKey)
            userDefaults.synchronize()
        }
        
        return clientID
    }
    
    private func randomStringWithLength(_ len: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = String()
        for _ in 0..<len {
            let length = UInt32(letters.count)
            let rand = arc4random_uniform(length)
            let index = String.Index(encodedOffset: Int(rand))
            randomString += String(letters[index])
        }
        return String(randomString)
    }
}

extension MQTTClientModel: MQTTSessionDelegate {
    func mqttDidReceive(message: MQTTMessage, from session: MQTTSession) {
        connectionType = "mqtt"
        var bytes = message.payload.bytes
        
        bytes.removeFirst()
        bytes.removeFirst()
        
        var arrayUInt8:[UInt8] = [message.payload.bytes[0]]
        arrayUInt8.append(message.payload.bytes[1])
        
        let str = self.toString(data: arrayUInt8)
        let endCharacters = device.internetToken!.suffix(2)
        if str == String(endCharacters) {
            if let fByte = bytes.first {
                if fByte == UInt8(TypeRequest.bossRequest.rawValue) {
                    var bossBytes = bytes
                    var bossDevice: Device?
                    if bossBytes.count>7 {
                        let range = 0...7
                        let snBytes = Array(bossBytes[1...6])
                        let snData = Data(snBytes)
                        if let snUtf8 = String(data: snData, encoding: .ascii) {
                            bossDevice = CoreDataStack.shared.devices?.first(where: { dv in
                                dv.serial == Int64(snUtf8)!
                            })
                        }
                        
                        bossBytes.removeSubrange(range)
                    }
                    print("---X--- BUS", bossDevice?.serial, bossBytes)
                    self.results?(bossBytes,bossDevice)
                    NWSocketConnection.instance.delegate?.recievedItem(bossBytes, bossDevice, tag: tag, dict: dict)
                } else {
                    print("---X--- GATEWAY", device.serial, bytes)
                    self.results?(bytes,device)
                    NWSocketConnection.instance.delegate?.recievedItem(bytes, device, tag: tag, dict: dict)
                }
            } else {
                results?(nil,nil)
            }
        } else {
            results?(nil,nil)
        }
        
        tag = 1111
        dict = nil
    }
    
    func mqttDidAcknowledgePing(from session: MQTTSession) {
        
    }
    
    func mqttDidDisconnect(session: MQTTSession, error: MQTTSessionError) {
        results?(nil,nil)
    }
}


extension MQTTClientModel {
    private func hexBytes(data: Data) -> String {
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
    
    private func decryptByte(data: Data, key: UInt8) -> String? {
        let bytes = data.bytes
        let inputBytes: [UInt8] = bytes.map { $0^key }
        guard let utf8String = String.init(bytes: inputBytes, encoding: .utf8) else { return nil }
        
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
        
        return String.init(data: data, encoding: .utf8)!
    }
}
