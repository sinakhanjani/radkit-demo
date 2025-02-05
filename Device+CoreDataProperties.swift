//
//  Device+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 6/16/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension Device {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Device> {
        return NSFetchRequest<Device>(entityName: "Device")
    }

//    @NSManaged public var connectionType: String?
    @NSManaged public var internetToken: String?
    @NSManaged public var ip: String?
    @NSManaged public var isLock: Bool
    @NSManaged public var isBossDevice: Bool
    @NSManaged public var isStatic: Bool
    @NSManaged public var localToken: String?
    @NSManaged public var name: String?
    @NSManaged public var password: String?
    @NSManaged public var port: Int64
    @NSManaged public var requestKey: Data?
    @NSManaged public var serial: Int64
    @NSManaged public var bridgeDeviceSerial: Int64
    @NSManaged public var staticIP: String?
    @NSManaged public var staticPort: String?
    @NSManaged public var type: Int64
    @NSManaged public var url: String?
    @NSManaged public var username: String?
    @NSManaged public var version: Int64
    @NSManaged public var wifibssid: String?
    @NSManaged public var relays: NSOrderedSet?
    @NSManaged public var inputStatus: NSOrderedSet?
    
}

// MARK: Generated accessors for relays
extension Device {

    @objc(insertObject:inRelaysAtIndex:)
    @NSManaged public func insertIntoRelays(_ value: Relay, at idx: Int)

    @objc(removeObjectFromRelaysAtIndex:)
    @NSManaged public func removeFromRelays(at idx: Int)

    @objc(insertRelays:atIndexes:)
    @NSManaged public func insertIntoRelays(_ values: [Relay], at indexes: NSIndexSet)

    @objc(removeRelaysAtIndexes:)
    @NSManaged public func removeFromRelays(at indexes: NSIndexSet)

    @objc(replaceObjectInRelaysAtIndex:withObject:)
    @NSManaged public func replaceRelays(at idx: Int, with value: Relay)

    @objc(replaceRelaysAtIndexes:withRelays:)
    @NSManaged public func replaceRelays(at indexes: NSIndexSet, with values: [Relay])

    @objc(addRelaysObject:)
    @NSManaged public func addToRelays(_ value: Relay)

    @objc(removeRelaysObject:)
    @NSManaged public func removeFromRelays(_ value: Relay)

    @objc(addRelays:)
    @NSManaged public func addToRelays(_ values: NSOrderedSet)

    @objc(removeRelays:)
    @NSManaged public func removeFromRelays(_ values: NSOrderedSet)

}

// MARK: Generated accessors for inputStatus
extension Device {

    @objc(insertObject:inInputStatusAtIndex:)
    @NSManaged public func insertIntoInputStatus(_ value: InputStatus, at idx: Int)

    @objc(removeObjectFromInputStatusAtIndex:)
    @NSManaged public func removeFromInputStatus(at idx: Int)

    @objc(insertInputStatus:atIndexes:)
    @NSManaged public func insertIntoInputStatus(_ values: [InputStatus], at indexes: NSIndexSet)

    @objc(removeInputStatusAtIndexes:)
    @NSManaged public func removeFromInputStatus(at indexes: NSIndexSet)

    @objc(replaceObjectInInputStatusAtIndex:withObject:)
    @NSManaged public func replaceInputStatus(at idx: Int, with value: InputStatus)

    @objc(replaceInputStatusAtIndexes:withInputStatus:)
    @NSManaged public func replaceInputStatus(at indexes: NSIndexSet, with values: [InputStatus])

    @objc(addInputStatusObject:)
    @NSManaged public func addToInputStatus(_ value: InputStatus)

    @objc(removeInputStatusObject:)
    @NSManaged public func removeFromInputStatus(_ value: InputStatus)

    @objc(addInputStatus:)
    @NSManaged public func addToInputStatus(_ values: NSOrderedSet)

    @objc(removeInputStatus:)
    @NSManaged public func removeFromInputStatus(_ values: NSOrderedSet)

}
