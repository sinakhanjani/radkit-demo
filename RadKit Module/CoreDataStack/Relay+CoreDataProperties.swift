//
//  Relay+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/27/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension Relay {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Relay> {
        return NSFetchRequest<Relay>(entityName: "Relay")
    }

    @NSManaged public var digit: Int64
    @NSManaged public var name: String?
    @NSManaged public var device: Device?
}
