//
//  EQRely+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 11/3/1398 AP.
//  Copyright © 1398 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension EQRely {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EQRely> {
        return NSFetchRequest<EQRely>(entityName: "EQRely")
    }

    @NSManaged public var cover: Data?
    @NSManaged public var data: Data?
    @NSManaged public var data2: Data?
    @NSManaged public var data3: Data?
    @NSManaged public var data4: Data?
    @NSManaged public var data5: Data?
    @NSManaged public var data6: Data?
    @NSManaged public var digit: Int64
    @NSManaged public var isContinual: Bool
    @NSManaged public var name: String?
    @NSManaged public var state: NSNumber?
    @NSManaged public var name2: String?
    @NSManaged public var name3: String?
    @NSManaged public var name4: String?
    @NSManaged public var name5: String?
    @NSManaged public var name6: String?
    @NSManaged public var eqDevice: EQDevice?

}
