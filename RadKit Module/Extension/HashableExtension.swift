//
//  HashableExtension.swift
//  Alaedin
//
//  Created by Sinakhanjani on 10/23/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit
import BigInt

extension String {
    
    enum RegularExpressions: String {
        case phone = "^\\s*(?:\\+?(\\d{1,3}))?([-. (]*(\\d{3})[-. )]*)?((\\d{3})[-. ]*(\\d{2,4})(?:[-.x ]*(\\d+))?)\\s*$"
    }
    
    func isValid(regex: RegularExpressions) -> Bool {
        return isValid(regex: regex.rawValue)
    }
    
    func isValid(regex: String) -> Bool {
        let matches = range(of: regex, options: .regularExpression)
        return matches != nil
    }
    
    func onlyDigits() -> String {
        let filtredUnicodeScalars = unicodeScalars.filter{CharacterSet.decimalDigits.contains($0)}
        return String(String.UnicodeScalarView(filtredUnicodeScalars))
    }
    
    func makeACall() {
        if isValid(regex: .phone) {
            if let url = URL(string: "tel://\(self.onlyDigits())"), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
}

extension String {
    
    var seperateByCama: String {
        guard self != "0" && self != "" && self != "0.00" && self != "0.0" else { return "0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let nsNumber = NSNumber(value: Int(self)!)
        let number = formatter.string(from: nsNumber)!
        
        return number
    }

}

extension Int {
    
    var seperateByCama: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let nsNumber = NSNumber(value: self)
        let number = formatter.string(from: nsNumber)!
        
        return number
    }

}

extension Array where Element: Hashable {
    
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
    
}

public extension Sequence where Element: Equatable {
    
    var uniqueElements: [Element] {
        return self.reduce(into: []) {
            uniqueElements, element in
            
            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
    }
    
    
}

extension Int {
    var convertToPersian:String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "fa_IR")
        formatter.currencySymbol=""
        if (self != 0) {
            return "\(formatter.string(from: self as NSNumber) ?? "")"
            
        } else {
            return ""
        }
    }
}

extension UnsignedInteger {
    var hex: String {
        var str = String(self, radix: 16, uppercase: true)
        while str.count < 2 * MemoryLayout<Self>.size {
            str.insert("0", at: str.startIndex)
        }
        return str
    }
}

extension String {
    
    func scan(components:String,split:String) -> [String] {
        let strArray = components.components(separatedBy: split)
//        print("scan is complete in: \n\(strArray) numbers")
        
        return strArray
    }
    
}

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    var jsonData: Data? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return jsonData
        } catch {
            return nil
        }
    }

    func printJson() {
        print(json)
    }
}

extension String {
    var isValidEmail: Bool { NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self) }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
