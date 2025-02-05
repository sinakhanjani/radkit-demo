import Foundation
import PlaygroundSupport


enum BitCalculator: UInt8 {
    case zero, one
    
    public var isOn: Bool {
        switch self {
        case .one:
            return true
        case .zero:
            return false
        }
    }
    
    private func asInt() -> Int {
        return (self == .one) ? 1 : 0
    }
    
    static public func toBits(fromByte number: Int) -> [BitCalculator] {
        var byte = UInt32(number)
        var bits = [BitCalculator](repeating: .zero, count: 32)
        
        for i in 0..<32 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            byte >>= 1
        }
        
        return bits
    }
    
    static private func toBytes(bits: [BitCalculator]) -> [UInt8] {
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
    
    static public func convert(bits32: [BitCalculator]) -> Int {
        assert(bits.count % 32 == 0, "Bit array size must be multiple of 32")
        
        var bits = bits32
        bits.reverse() // this is for convert than you cab send it to server
        let array = BitCalculator.toBytes(bits: bits)
        var value: UInt32 = 0
        let data = NSData(bytes: array, length: array.count)
        data.getBytes(&value, length: array.count)
        value = UInt32(bigEndian: value)

        return Int(value)
    }
}

let x = 73738
var bits = BitCalculator.toBits(fromByte: x)
bits.count
BitCalculator.convert(bits32: bits)

bits[1].isOn // true
bits[2].isOn // false

func convert(str: String) -> [String] {
    guard let data = str.data(using: .utf8),
          let arrayOfStrings = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] else {
            fatalError()
    }
    
    return arrayOfStrings
}
let source = "[\"word1\",\"word2\"]"
let y = convert(str: source)

print(y.description)



let string = ["1","2","3","4","5"]

let newString = "\"[\"" + string.joined(separator: "\",\"") + "\"]\""

print(newString) // Prints "["1","2","3","4","5"]"
