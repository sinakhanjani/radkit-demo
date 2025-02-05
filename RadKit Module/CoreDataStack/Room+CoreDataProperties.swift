//
//  Room+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/10/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension Room {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Room> {
        return NSFetchRequest<Room>(entityName: "Room")
    }

    @NSManaged public var id: Int64
    @NSManaged public var image: Data?
    @NSManaged public var name: String?
    @NSManaged public var equipments: NSOrderedSet?

}

// MARK: Generated accessors for equipments
extension Room {

    @objc(insertObject:inEquipmentsAtIndex:)
    @NSManaged public func insertIntoEquipments(_ value: Equipment, at idx: Int)

    @objc(removeObjectFromEquipmentsAtIndex:)
    @NSManaged public func removeFromEquipments(at idx: Int)

    @objc(insertEquipments:atIndexes:)
    @NSManaged public func insertIntoEquipments(_ values: [Equipment], at indexes: NSIndexSet)

    @objc(removeEquipmentsAtIndexes:)
    @NSManaged public func removeFromEquipments(at indexes: NSIndexSet)

    @objc(replaceObjectInEquipmentsAtIndex:withObject:)
    @NSManaged public func replaceEquipments(at idx: Int, with value: Equipment)

    @objc(replaceEquipmentsAtIndexes:withEquipments:)
    @NSManaged public func replaceEquipments(at indexes: NSIndexSet, with values: [Equipment])

    @objc(addEquipmentsObject:)
    @NSManaged public func addToEquipments(_ value: Equipment)

    @objc(removeEquipmentsObject:)
    @NSManaged public func removeFromEquipments(_ value: Equipment)

    @objc(addEquipments:)
    @NSManaged public func addToEquipments(_ values: NSOrderedSet)

    @objc(removeEquipments:)
    @NSManaged public func removeFromEquipments(_ values: NSOrderedSet)

}

extension Room : Identifiable {

}
