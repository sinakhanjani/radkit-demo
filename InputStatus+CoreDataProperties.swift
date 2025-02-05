//
//  InputStatus+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 6/16/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData

extension InputStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InputStatus> {
        return NSFetchRequest<InputStatus>(entityName: "InputStatus")
    }

    @NSManaged public var name: String?
    @NSManaged public var status: Bool
    @NSManaged public var relationship: Device?

}
