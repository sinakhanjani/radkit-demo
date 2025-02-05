//
//  DataExtension.swift
//  Alaedin
//
//  Created by Sinakhanjani on 10/22/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension Data {
    var bytes : [UInt8] {
        return [UInt8](self)
    }
}

extension Data {
    static func toBits(bytes: [UInt8]) -> [Bit] {
        //        let u16 = UnsafePointer(bytes.reversed()).withMemoryRebound(to: UInt16.self, capacity: 1) {
        //            $0.pointee
        //        }
        // return //self.bits(fromByte: 0)
        if bytes.count > 1 {
            let byte1 = bits8(fromByte: bytes[0])
            let byte2 = bits8(fromByte: bytes[1])
            let bites = byte2 + byte1
            return bites
        } else {
            let byte1 = bits8(fromByte: bytes[0])
            let byte2 = bits8(fromByte: UInt8(0))
            let bites = byte2 + byte1
            return bites
        }
    }
    
    enum Bit: UInt8, CustomStringConvertible {
        case zero, one
        
        var description: String {
            switch self {
            case .one:
                return "1"
            case .zero:
                return "0"
            }
        }
        
        func asInt() -> Int {
            return (self == .one) ? 1 : 0
        }
    }
    
    static private func bits(fromByte byte: UInt16) -> [Bit] {
        var byte = byte
        var bits = [Bit](repeating: .zero, count: 16)
        for i in 0..<16 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            byte >>= 1
        }
        
        return bits
    }
    
    static func bitsToBytes(bits: [Bit]) -> [UInt8] {
        assert(bits.count % 8 == 0, "Bit array size must be multiple of 8")
        
        let numBytes = 1 + (bits.count - 1) / 8
        
        var bytes = [UInt8](repeating : 0, count : numBytes)
        for pos in 0 ..< numBytes {
            let val = 128 * bits[8 * pos].asInt() +
            64 * bits[8 * pos + 1].asInt() +
            32 * bits[8 * pos + 2].asInt() +
            16 * bits[8 * pos + 3].asInt() +
            8 * bits[8 * pos + 4].asInt() +
            4 * bits[8 * pos + 5].asInt() +
            2 * bits[8 * pos + 6].asInt() +
            1 * bits[8 * pos + 7].asInt()
            bytes[pos] = UInt8(val)
        }
        
        return bytes
    }
    
    static func bits8(fromByte byte: UInt8) -> [Bit] {
        var byte = byte
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0..<16 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            byte >>= 1
        }
        
        return bits
    }
    
}

extension Data {
    var uint16: UInt16 {
        let x = withUnsafeBytes { $0.bindMemory(to: UInt16.self) }
        print("HELP",x, x[0])
        return x[0]
    }
}
