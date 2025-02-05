//
//  Command+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/27/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension Command {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Command> {
        return NSFetchRequest<Command>(entityName: "Command")
    }
    
    @NSManaged public var deviceName: String?
    @NSManaged public var deviceSerial: Int64
    @NSManaged public var deviceType: Int64
    @NSManaged public var sendData: Data?
    @NSManaged public var time: Double
    @NSManaged public var senario: Senario?

}
