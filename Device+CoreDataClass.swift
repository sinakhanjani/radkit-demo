//
//  Device+CoreDataClass.swift
//  RadKit Module
//
//  Created by Sina khanjani on 6/16/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData

enum ConnectionState {
    case wifi
    case ipStatic
    case mqtt
    case none
}

@objc(Device)
public class Device: NSManagedObject {
    
    var connectionState: ConnectionState {
        let connection = NWSocketConnection.instance.connectionTypeFor(device: self)
        if WebAPI.instance.reachability.connection == .none {
            return .none
        }
        if connection?.tcp.connectionType == "tcp" && self.isStatic {
            return .ipStatic
        }
        if connection?.tcp.connectionType == "tcp" && !self.isStatic {
            return .wifi
        }
        if connection?.mqtt.connectionType == "mqtt" {
            return .mqtt
        }
        return .none
    }
}
