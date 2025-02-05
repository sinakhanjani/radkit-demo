//
//  UDPConnection.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/16/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import Foundation

class UDPBroadcast {
    static let instance = UDPBroadcast()
        
    public func UDPBroadcast1(addModule:Bool=false,escape: ((_ status: Status,_ device:Device?) -> Void)?) {
        do {
            let broadcastConnection = try UDPBroadcastConnection(
                port: 56792,
                handler: { (ipAddress: String, port: Int, data: Data) -> Void in
                    print("udp1 connection received from \(ipAddress):\(port)", data)
                    if let item = self.decryptByte(data: data, key: 155) {
                        var scan = item.scan(components: item, split: ":")
                        print(scan)
                        if addModule {
                            if let type = Int(scan[0]) {
                                CoreDataStack.shared.addRadkitModule(internetToken: scan[8], localToken: scan[7], username: scan[5], password: scan[6], port: Int(scan[4])!, serial: Int(scan[1])!, type: type, url: scan[3], version: Int(scan[2])!,ip: ipAddress, wifibssid: EspTouchManager.shared.espTouch_bssid, escape: { (state,device) in
                                    if state == .deviceAdded {
                                        escape?(.deviceAdded,device)
                                    }
                                })
                            }
                            if scan[0] == "B" {
                                // ["B", "04", "10", "146040", "15", "s1.imaxbms.com", "22199", "838163", "178889", "kbDKIK", "KBEBHM", "60", "001001", "15", "55", "001002", "15", "59", "001003", "15", "53", "001004", "15", ""]
                                let bosDeviceCount = Int(scan[1])!
                                scan = Array(scan[2...scan.count-1])
                                
                                var bossDevices = Array(scan[9...])
                                var bossDeviceItems: [[String]] = []
                                for _ in 0..<bosDeviceCount {
                                    var arr = [String]()
                                    arr.append(bossDevices[0])
                                    arr.append(bossDevices[1])
                                    arr.append(bossDevices[2])
                                    
                                    bossDevices.removeFirst()
                                    bossDevices.removeFirst()
                                    bossDevices.removeFirst()
                                    
                                    bossDeviceItems.append(arr)
                                }
                                
                                if scan[3].hasSuffix("imaxbms.com") {
                                    bossDeviceItems.forEach { item in
                                        CoreDataStack.shared.addRadkitModule(internetToken: "", localToken: "", username: "", password: "", port: 0, serial: Int(item[1])!, type: Int(item[0])!-50, url: "", version: Int(item[2])!,ip: "", wifibssid: EspTouchManager.shared.espTouch_bssid, isBossDevice: true, bridgeDeviceSerial: Int(scan[1])!, escape: { (state,device) in
                                            if state == .deviceAdded {
                                                escape?(.deviceAdded,device)
                                            }
                                        })
                                    }
                                }
                                
                                CoreDataStack.shared.addRadkitModule(internetToken: scan[8], localToken: scan[7], username: scan[5], password: scan[6], port: Int(scan[4])!, serial: Int(scan[1])!, type: Int(scan[0])!, url: scan[3], version: Int(scan[2])!,ip: ipAddress, wifibssid: EspTouchManager.shared.espTouch_bssid, escape: { (state,device) in
                                    if state == .deviceAdded {
                                        escape?(.deviceAdded,device)
                                    }
                                })
                            }
                        }
                        CoreDataStack.shared.updateTokenInDatabaseModules(localToken: scan[7], internetToken: scan[8], serial: Int(scan[1])!)
                        print("all devices 'token' is now updated.")
                        escape?(.success,nil)
                    } else {
                        escape?(.failed,nil)
                    }
                },
                errorHandler: { (error) in
                    escape?(.failed,nil)
                    print("error: \(error)\n")
            })
            
            try broadcastConnection.sendBroadcast(encryptByte(input: "rad", key: 155))
        } catch {
            escape?(.failed,nil)
            print("error: \(error)\n")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
            guard let self = self else { return }
            iOS13UDP.fullScanUDP(fullScanData: self.encryptByte(input: "rad", key: 155), port: 56792) { [weak self] (ipAddress, port, data) in
                guard let self = self else { escape?(.failed,nil); return }
                print("udp1 connection received from fullscan \(ipAddress) : \(port)")
                if let item = self.decryptByte(data: data, key: 155) {
                    var scan = item.scan(components: item, split: ":")
                    print(scan)
                    if addModule {
                        if let type = Int(scan[0]) {
                            CoreDataStack.shared.addRadkitModule(internetToken: scan[8], localToken: scan[7], username: scan[5], password: scan[6], port: Int(scan[4])!, serial: Int(scan[1])!, type: type, url: scan[3], version: Int(scan[2])!,ip: ipAddress, wifibssid: EspTouchManager.shared.espTouch_bssid, escape: { (state,device) in
                                if state == .deviceAdded {
                                    escape?(.deviceAdded,device)
                                }
                            })
                        }
                        if scan[0] == "B" {
                            // ["B", "04", "10", "146040", "15", "s1.imaxbms.com", "22199", "838163", "178889", "kbDKIK", "KBEBHM", "60", "001001", "15", "55", "001002", "15", "59", "001003", "15", "53", "001004", "15", ""]
                            let bosDeviceCount = Int(scan[1])!
                            scan = Array(scan[2...scan.count-1])
                            
                            var bossDevices = Array(scan[9...])
                            var bossDeviceItems: [[String]] = []
                            for _ in 0..<bosDeviceCount {
                                var arr = [String]()
                                arr.append(bossDevices[0])
                                arr.append(bossDevices[1])
                                arr.append(bossDevices[2])
                                
                                bossDevices.removeFirst()
                                bossDevices.removeFirst()
                                bossDevices.removeFirst()
                                
                                bossDeviceItems.append(arr)
                            }
                            
                            if scan[3].hasSuffix("imaxbms.com") {
                                bossDeviceItems.forEach { item in
                                    CoreDataStack.shared.addRadkitModule(internetToken: "", localToken: "", username: "", password: "", port: 0, serial: Int(item[1])!, type: Int(item[0])!-50, url: "", version: Int(item[2])!,ip: "", wifibssid: EspTouchManager.shared.espTouch_bssid, isBossDevice: true, bridgeDeviceSerial: Int(scan[1])!, escape: { (state,device) in
                                        if state == .deviceAdded {
                                            escape?(.deviceAdded,device)
                                        }
                                    })
                                }
                            }
                            
                            CoreDataStack.shared.addRadkitModule(internetToken: scan[8], localToken: scan[7], username: scan[5], password: scan[6], port: Int(scan[4])!, serial: Int(scan[1])!, type: Int(scan[0])!, url: scan[3], version: Int(scan[2])!,ip: ipAddress, wifibssid: EspTouchManager.shared.espTouch_bssid, escape: { (state,device) in
                                if state == .deviceAdded {
                                    escape?(.deviceAdded,device)
                                }
                            })
                        }
                    }
                    CoreDataStack.shared.updateTokenInDatabaseModules(localToken: scan[7], internetToken: scan[8], serial: Int(scan[1])!)
                    print("all devices 'token' is now updated.")
                    escape?(.success,nil)
                } else {
                    escape?(.failed,nil)
                }
            }
        }
    }
    
    public func UDPBroadcast2(escape: ((_ status: Status,_ device:Device?) -> Void)?) {
        guard let _ = CoreDataStack.shared.devices else { escape?(.failed,nil) ; return }
        guard !CoreDataStack.shared.devices!.isEmpty else { escape?(.failed,nil) ; return }
        do {
            let broadcastConnection = try UDPBroadcastConnection(
                port: 56792,
                handler: { [weak self] (ipAddress: String, port: Int, data: Data) -> Void in
                    guard let self = self else {
                        escape?(.failed,nil)
                        return
                    }
                    print("udp2 connection received from \(ipAddress) : \(port)")
                    if let item = self.decryptByte(data: data, key: 155) {
                        if CoreDataStack.shared.updateIPInDatabaseModules(serial: Int(item)!, ip: ipAddress).0 == .changedIP {
                            escape?(.changedIP,CoreDataStack.shared.updateIPInDatabaseModules(serial: Int(item)!, ip: ipAddress).1)
                        } else {
                            escape?(.success,nil)
                        }
                    } else {
                        escape?(.failed,nil)
                    }
            },
                errorHandler: { (error) in
                    escape?(.failed, nil)
                    print("error: \(error)\n")
            })
            if let devices = CoreDataStack.shared.devices {
                let ids = (devices.filter({ !$0.isBossDevice }).map { $0.localToken! }).joined(separator: ":")
                let send = "rad"+ids+":"
                
                try broadcastConnection.sendBroadcast(encryptByte(input: send, key: 155))
            } else {
                escape?(.failed, nil)
            }
        } catch {
            escape?(.failed,nil)
            print("Error: \(error)\n")
        }
        // full scan method
        if let devices = CoreDataStack.shared.devices {
            let ids = (devices.filter({ !$0.isBossDevice }).map { $0.localToken! }).joined(separator: ":")
            let send = "rad"+ids+":"
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
                guard let self = self else { return }
                iOS13UDP.fullScanUDP(fullScanData: self.encryptByte(input: send, key: 155), port: 56792) { [weak self] (ipAddress, port, data) in
                    guard let self = self else {
                        escape?(.failed,nil)
                        return
                    }
                    print("udp2 connection received from fullscan \(ipAddress) : \(port)")
                    if let item = self.decryptByte(data: data, key: 155) {
                        if CoreDataStack.shared.updateIPInDatabaseModules(serial: Int(item)!, ip: ipAddress).0 == .changedIP {
                            escape?(.changedIP,CoreDataStack.shared.updateIPInDatabaseModules(serial: Int(item)!, ip: ipAddress).1)
                        } else {
                            escape?(.success,nil)
                        }
                    } else {
                        escape?(.failed,nil)
                    }
                }
            }
        } else {
            escape?(.failed, nil)
        }
    }
    
    private func decryptByte(data:Data, key:UInt8) -> String? {
        var bytes = data.bytes
        let inputBytes: [UInt8] = bytes.map { $0^key }
        
        guard let utf8String = String.init(bytes: inputBytes, encoding: .utf8) else {
            let crcHByte = bytes.removeLast() // 194
            let crcLByte = bytes.removeLast() // 90
            let unint16 = UInt16(crcLByte) << 8 | UInt16(crcHByte)
            
            let inputBytesCRC: [UInt8] = bytes.map { $0^key }
            let crc16ccitt = Data(bytes).crc16ccitt_xmodem()

//            let uInt8Value0 = crc16ccitt >> 8
//            let uInt8Value1 = UInt8(crc16ccitt & 0x00ff)
            
            if unint16 == crc16ccitt {
                if let utf8StringCRC = String.init(bytes: inputBytesCRC, encoding: .utf8) {
                    return utf8StringCRC
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        return utf8String
    }
    
    private func encryptByte(input:String, key:UInt8) -> Data {
        var inputBytes: [UInt8] = Array(input.utf8).map { $0^key }
        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
        let data = Data.init(referencing: nsdata)
        return data
    }
}

extension Data {
    
    typealias bit_order_16 = (_ value: UInt16) -> UInt16
    typealias bit_order_8 = (_ value: UInt8) -> UInt8
    
    func straight_16(value: UInt16) -> UInt16 {
        return value
    }
    
    func reverse_16(value: UInt16) -> UInt16 {
        var value = value
        var reversed: UInt16 = 0
        for _ in 0..<16 {
            reversed <<= 1
            reversed |= (value & 0x1)
            value >>= 1
        }
        return reversed
    }
    
    func straight_8(value: UInt8) -> UInt8 {
        return value
    }
    
    func reverse_8(value: UInt8) -> UInt8 {
        var value = value
        var reversed: UInt8 = 0
        for _ in 0..<8 {
            reversed <<= 1
            reversed |= (value & 0x1)
            value >>= 1
        }
        return reversed
    }
    
    func crc16(data_order: bit_order_8, remainder_order: bit_order_16, remainder: UInt16, polynomial: UInt16) -> UInt16 {
        var remainder = remainder
        
        for byte in self {
            remainder ^= UInt16(data_order(byte)) << 8
            for _ in 0..<8 {
                if (remainder & 0x8000) != 0 {
                    remainder = (remainder << 1) ^ polynomial
                } else {
                    remainder = (remainder << 1)
                }
            }
        }
        return remainder_order(remainder)
    }
    
    func crc16ccitt() -> UInt16 {
        return crc16(data_order: straight_8, remainder_order: straight_16, remainder: 0xffff, polynomial: 0x1021)
    }
    
    func crc16ccitt_xmodem() -> UInt16 {
        return crc16(data_order: straight_8, remainder_order: straight_16, remainder: 0x0000, polynomial: 0x1021)
    }
    
    func crc16ccitt_kermit() -> UInt16 {
        let swap = crc16(data_order: reverse_8, remainder_order: reverse_16, remainder: 0x0000, polynomial: 0x1021)
        return swap.byteSwapped
    }
    
    func crc16ccitt_1d0f() -> UInt16 {
        return crc16(data_order: straight_8, remainder_order: straight_16, remainder: 0x1d0f, polynomial: 0x1021)
    }
    
    func crc16ibm() -> UInt16 {
        return crc16(data_order: reverse_8, remainder_order: reverse_16, remainder: 0x0000, polynomial: 0x8005)
    }
}


// apple review
/*
 Multicast Networking Entitlement Request
 This entitlement allows advanced networking apps to interact with their local network by sending multicast and broadcast IP packets and browsing for arbitrary Bonjour service types. Your app may need to access this level of networking in order to communicate with custom or non-standard devices or to act as a network utility. If your app needs this entitlement to function properly on iOS 14 or later, provide the following information.
 https://developer.apple.com/contact/request/networking-multicast
 */

/*
 [28: No space left on device]:
 https://stackoverflow.com/questions/67318867/error-domain-nsposixerrordomain-code-28-no-space-left-on-device-userinfo-kcf
 */

/*
 APN
 Name:Radkit
 Key ID:M6CUT79GWA
 Team ID:6M6HL93UMT
 Services:Apple Push Notifications service (APNs)
 */
