//
//  NWSocketConnectionExtension.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/17/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import Foundation

extension NWSocketConnection {
    func sendRequestDimmerOrRGB(tag:Int,device:Device,typeRequest: TypeRequest,items: [Int:UInt8],isDimmer: Bool,isDaem: Bool,rgb:RGB?,isWithFirstThree:Bool?=nil,beforSendData: ((_ bytes: [UInt8]?) -> Void)?=nil, completion: @escaping (_ device: Device?, _ bytes: [UInt8]?) -> Void) {
        if typeRequest == .directRequest {
            var bits = [Data.Bit](repeating: .zero, count: 8)
            if isDaem {
                bits[7] = .one
            } else {
                bits[7] = .zero
            }
            print("BITS",bits)
            var data = [UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)]
            for (key,value) in items {
                bits[key-1] = .one
                data[key] = value
            }
            let byte0 = Data.bitsToBytes(bits: bits.reversed())[0]
            data[0] = byte0
            if isDimmer {
                data[7] = UInt8(101)
                data[8] = UInt8(101)
                if let condition = isWithFirstThree {
                    if condition {
                        data[9] = UInt8(100)
                        data[10] = UInt8(101)
                    } else {
                        data[9] = UInt8(101)
                        data[10] = UInt8(100)
                    }
                }
                beforSendData?(data)
                print("Dimmer - will 'direct' send data",data)
            } else {
                if items.count == 3 {
                    data[7] = UInt8(101)
                    data[8] = UInt8(101)
                    data[9] = UInt8(101)
                    data[10] = UInt8(101)
                } else if items.count == 0 {
                    guard let rgb = rgb else { return }
                    if rgb.type == 1 {
                        data[7] = rgb.speed != nil ? rgb.speed!:UInt8(101)
                        data[8] = UInt8(101)
                        data[9] = rgb.light != nil ? rgb.light!:UInt8(101)
                        data[10] = UInt8(101)
                    } else {
                        data[7] = UInt8(101)
                        data[8] = rgb.speed != nil ? rgb.speed!:UInt8(101)
                        data[9] = UInt8(101)
                        data[10] = rgb.light != nil ? rgb.light!:UInt8(101)
                    }
                }
                beforSendData?(data)
                print("RGB - will 'direct' send data",data)
            }
            NWSocketConnection.instance.send(tag: tag,device: device, typeRequest: .directRequest, data: data) { (bytes, device) in
                completion(device,bytes)
            }
        }
        if typeRequest == .otherRequest {
            guard let rgb = rgb else { return }
            var data = [UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)]
            data[0] = rgb.type == 1 ? UInt8(1):UInt8(2)
            if let effectType = rgb.effectType {
                switch effectType {
                case 2:
                    data[1] = UInt8(2)
                case 3:
                    data[1] = UInt8(3)
                case 4:
                    data[1] = UInt8(4)
                case 5:
                    data[1] = UInt8(5)
                default:
                    break
                }
                if effectType == 2 {
                    data[2] = items[1]!
                    data[3] = items[2]!
                    data[4] = items[3]!
                    data[5] = items[4]!
                    data[6] = items[5]!
                    data[7] = items[6]!
                }
            }
            beforSendData?(data)
            print("RGB - Will 'Motefareqeh' Send Data",data)
            NWSocketConnection.instance.send(tag: tag,device: device, typeRequest: .otherRequest, data: data) { (bytes, device) in
                completion(device,bytes)
            }
        }
    }
}

extension NWSocketConnection {
    func dataRGBForSenario(items: [Int:UInt8],isDimmer: Bool,rgb:RGB?,isWithFirstThree:Bool?=nil) -> [UInt8] {
        var bits = [Data.Bit](repeating: .zero, count: 8)
        print("BITS",bits)
        var data = [UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)]
        for (key,value) in items {
            bits[key-1] = .one
            data[key] = value
        }
        let byte0 = Data.bitsToBytes(bits: bits.reversed())[0]
        data[0] = byte0
        if isDimmer {
            data[7] = UInt8(101)
            data[8] = UInt8(101)
            if let condition = isWithFirstThree {
                if condition {
                    data[9] = UInt8(100)
                    data[10] = UInt8(101)
                } else {
                    data[9] = UInt8(101)
                    data[10] = UInt8(100)
                }
            }
            print("Dimmer - will 'direct,Senario' send data",data)
            return data
        } else {
            if items.count == 3 {
                data[7] = UInt8(101)
                data[8] = UInt8(101)
                data[9] = UInt8(101)
                data[10] = UInt8(101)
            }
            if let rgb = rgb {
                if rgb.type == 1 {
                    data[7] = UInt8(101)
                    data[8] = UInt8(101)
                    data[9] = rgb.light != nil ? rgb.light!:UInt8(101)
                    data[10] = UInt8(101)
                } else {
                    data[7] = UInt8(101)
                    data[8] = UInt8(101)
                    data[9] = UInt8(101)
                    data[10] = rgb.light != nil ? rgb.light!:UInt8(101)
                }
            }
            print("RGB - will 'direct,Senario' send data",data)
            return data
        }
    }
    
    func dataRGBForWeekly(items: [Int:UInt8],isDimmer: Bool,rgb:RGB?,isWithFirstThree:Bool?=nil) -> [UInt8] {
        var bits = [Data.Bit](repeating: .zero, count: 8)
        print("BITS",bits)
        var data = [UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0),UInt8(0)]
        for (key,value) in items {
            bits[key-1] = .one
            data[key] = value
        }
        let byte0 = Data.bitsToBytes(bits: bits.reversed())[0]
        data[0] = byte0
        if isDimmer {
            if let condition = isWithFirstThree {
                if condition {
                    data[7] = UInt8(100)
                    data[8] = UInt8(101)
                } else {
                    data[7] = UInt8(101)
                    data[8] = UInt8(100)
                }
            }
            print("Dimmer - will 'direct,Weekly' send data",data)
            return data
        } else {
            if items.count == 3 {
                data[7] = UInt8(101)
                data[8] = UInt8(101)
            }
            if let rgb = rgb {
                if rgb.type == 1 {
                    data[7] = rgb.light != nil ? rgb.light!:UInt8(101)
                    data[8] = UInt8(101)
                } else {
                    data[7] = UInt8(101)
                    data[8] = rgb.light != nil ? rgb.light!:UInt8(101)
                }
            }
            print("RGB - will 'direct,Weekly' send data",data)
            return data
        }
    }
}
