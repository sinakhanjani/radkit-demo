//
//  UserInformation.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import Foundation

struct UserInformation: Codable {

    static public var archiveURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("userInfo").appendingPathExtension("inf")
    }
    
    static func encode(userInfo: UserInformation, directory dir: URL) {
        let propertyListEncoder = PropertyListEncoder()
        if let encodedProduct = try? propertyListEncoder.encode(userInfo) {
            try? encodedProduct.write(to: dir, options: .noFileProtection)
        }
    }
    
    static func decode(directory dir: URL) -> UserInformation? {
        let propertyListDecoder = PropertyListDecoder()
        if let retrievedProductData = try? Data.init(contentsOf: dir), let decodedProduct = try? propertyListDecoder.decode(UserInformation.self, from: retrievedProductData) {
            return decodedProduct
        }
        return nil
    }
}

struct Profile:Codable {
    var name: String?
    var mobile: String?
    var email: String?
    var apikey: String
}

struct Respo: Codable {
    var profile: Profile
    var message:String
    var error: Bool
    
    enum CodingKeys: String, CodingKey {
        case profile, error
        case message = "message"
    }
}
