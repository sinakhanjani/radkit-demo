//
//  TCPClientModel.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/17/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import Network
import Foundation

class TCPClientModel {
    var connection: NWConnection?
    
    var device: Device
    var connectionType = "none"
    var tag: Int = 1111
    var dict: Dictionary<String,Any>?
    
    let parames: NWParameters = {
        let tcpOptions: NWProtocolTCP.Options = {
            let options = NWProtocolTCP.Options()
            options.enableFastOpen = true // Enable TCP Fast Open (TFO)
            options.connectionTimeout = 5 // connection timed out

            return options
        }()
        
        let parames = NWParameters(tls: nil, tcp: tcpOptions)
        if let isOption = parames.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            isOption.version = .v4
        }
        parames.preferNoProxies = true
        parames.expiredDNSBehavior = .allow
        parames.multipathServiceType = .interactive
        parames.serviceClass = .background

        return parames
    }()
    
    init(device: Device) {
        self.device = device
    }
    
    func setupSwiftTCPSocket(escapeTCP: ((_ bytes: [UInt8]?,_ device:Device?) -> Void)?) {
        var ip: String
        var port: Int

        if device.isStatic {
            ip = device.staticIP!
            port = Int(device.staticPort ?? "")!

            connection = NWConnection(host:  NWEndpoint.Host("\(ip)"), port:  NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)), using: parames)
        } else {
            ip = device.ip!
            port = 1720

            connection = NWConnection(host: NWEndpoint.Host("\(ip)"), port: 1720, using: parames)
        }
        
        // connection handler
        connection?.stateUpdateHandler = { [weak self] (newState) in
            guard let self = self else { return }
            switch (newState) {
            case .ready:
                print("State: Ready\n")
                self.sendTCPData(nil)
                self.receiveTCPData() { [weak self] didRead in
                    guard let self = self else { return }
                    if let didRead = didRead {
                        self.connectionType = "tcp"
                        if didRead.count == 1 {
                            let data = didRead
                            self.device.requestKey = data
//                            CoreDataStack.shared.saveContext()
                            print("Socket in now connected to device \(self.device.serial) with \(ip) with key: \(data.bytes)")
                            escapeTCP?(data.bytes,self.device)
                        } else {
                            let data = didRead
                            if data.bytes.count == 1 {
                                print("---*--- WARNING KEY WARNING ---*---", data.bytes)
                                self.device.requestKey = data
//                                CoreDataStack.shared.saveContext()
                                escapeTCP?(nil,nil)
                                return
                            }
                            guard let key = (self.device.requestKey as Data?)?.bytes.first else {
                                escapeTCP?(nil,nil)
                                return
                            }
                            let bytes = self.decryptByteBySubtracting(key: key, data: data.bytes)
                            print("---*--- START",self.device.serial,bytes)
                            escapeTCP?(bytes,self.device)
                        }
                    }
                }
            case .setup:
                print("State: Setup \(self.device.serial)\n")
                self.connectionType = "none"
            case .cancelled:
                print("State: Cancelled \(self.device.serial)\n")
                self.connectionType = "none"
            case .preparing:
                self.connectionType = "none"
                print("State: Preparing \(self.device.serial)\n")
            default:
                self.connectionType = "none"
                print("ERROR! State not defined! \(self.device.serial)\n")
            }
        }

        // connect tcp
        connection?.start(queue: .global())
    }
    
    func sendTCPData(_ data: Data?) {
        connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                if let _ = data {
//                    print("Data: \(data) was sent to TCP")
                }
            } else {
//                print("ERROR! Error when data sending. NWError: \n \(NWError!)")
            }
        })))
    }
    
    func receiveTCPData(completion: @escaping (_ data: Data?) -> Void) {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isComplete, error) in
            if error == nil {
                completion(data)
            } else {
                self?.connectionType = "none"
//                print("ERROR! Error when data receiving. NWError: \n \(error!)")
            }
            self?.tag = 1111
            self?.dict = nil
        }
    }
}

extension TCPClientModel {
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
