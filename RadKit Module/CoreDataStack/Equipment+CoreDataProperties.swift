//
//  Equipment+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/27/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension Equipment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Equipment> {
        return NSFetchRequest<Equipment>(entityName: "Equipment")
    }

    @NSManaged public var id: Int64
    @NSManaged public var image: Data?
    @NSManaged public var name: String?
    @NSManaged public var type: Int64
    @NSManaged public var eqDevice: NSOrderedSet?
    @NSManaged public var room: Room?
    @NSManaged public var isShortcut: Bool
    @NSManaged public var senarioId: Int64

}

// MARK: Generated accessors for eqDevice
extension Equipment {

    @objc(insertObject:inEqDeviceAtIndex:)
    @NSManaged public func insertIntoEqDevice(_ value: EQDevice, at idx: Int)

    @objc(removeObjectFromEqDeviceAtIndex:)
    @NSManaged public func removeFromEqDevice(at idx: Int)

    @objc(insertEqDevice:atIndexes:)
    @NSManaged public func insertIntoEqDevice(_ values: [EQDevice], at indexes: NSIndexSet)

    @objc(removeEqDeviceAtIndexes:)
    @NSManaged public func removeFromEqDevice(at indexes: NSIndexSet)

    @objc(replaceObjectInEqDeviceAtIndex:withObject:)
    @NSManaged public func replaceEqDevice(at idx: Int, with value: EQDevice)

    @objc(replaceEqDeviceAtIndexes:withEqDevice:)
    @NSManaged public func replaceEqDevice(at indexes: NSIndexSet, with values: [EQDevice])

    @objc(addEqDeviceObject:)
    @NSManaged public func addToEqDevice(_ value: EQDevice)

    @objc(removeEqDeviceObject:)
    @NSManaged public func removeFromEqDevice(_ value: EQDevice)

    @objc(addEqDevice:)
    @NSManaged public func addToEqDevice(_ values: NSOrderedSet)

    @objc(removeEqDevice:)
    @NSManaged public func removeFromEqDevice(_ values: NSOrderedSet)

}
