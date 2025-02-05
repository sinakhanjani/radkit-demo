//
//  URLExtension.swift
//  Alaedin
//
//  Created by Sinakhanjani on 10/21/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import Foundation

extension URL {
    
    static func bundleURL(source: String, ext: String) -> URL {
        return Bundle.main.url(forResource: source, withExtension: ext)!
    }
    
}

extension URL {
    
    func withQuries(_ queries:[String:String]) -> URL? {
        var components = URLComponents.init(url: self, resolvingAgainstBaseURL: true)
        components?.queryItems = queries.compactMap {
            URLQueryItem.init(name: $0.0, value: $0.1)
        }
        return components?.url
    }
    
}


