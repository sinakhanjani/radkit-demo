//
//  EQDevice+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/27/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension EQDevice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EQDevice> {
        return NSFetchRequest<EQDevice>(entityName: "EQDevice")
    }

    @NSManaged public var name: String?
    @NSManaged public var serial: Int64
    @NSManaged public var type: Int64
    @NSManaged public var eqRelays: NSOrderedSet?

}

// MARK: Generated accessors for eqRelays
extension EQDevice {

    @objc(insertObject:inEqRelaysAtIndex:)
    @NSManaged public func insertIntoEqRelays(_ value: EQRely, at idx: Int)

    @objc(removeObjectFromEqRelaysAtIndex:)
    @NSManaged public func removeFromEqRelays(at idx: Int)

    @objc(insertEqRelays:atIndexes:)
    @NSManaged public func insertIntoEqRelays(_ values: [EQRely], at indexes: NSIndexSet)

    @objc(removeEqRelaysAtIndexes:)
    @NSManaged public func removeFromEqRelays(at indexes: NSIndexSet)

    @objc(replaceObjectInEqRelaysAtIndex:withObject:)
    @NSManaged public func replaceEqRelays(at idx: Int, with value: EQRely)

    @objc(replaceEqRelaysAtIndexes:withEqRelays:)
    @NSManaged public func replaceEqRelays(at indexes: NSIndexSet, with values: [EQRely])

    @objc(addEqRelaysObject:)
    @NSManaged public func addToEqRelays(_ value: EQRely)

    @objc(removeEqRelaysObject:)
    @NSManaged public func removeFromEqRelays(_ value: EQRely)

    @objc(addEqRelays:)
    @NSManaged public func addToEqRelays(_ values: NSOrderedSet)

    @objc(removeEqRelays:)
    @NSManaged public func removeFromEqRelays(_ values: NSOrderedSet)

}
