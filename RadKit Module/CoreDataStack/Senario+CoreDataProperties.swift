//
//  Senario+CoreDataProperties.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/10/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//
//

import Foundation
import CoreData


extension Senario {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Senario> {
        return NSFetchRequest<Senario>(entityName: "Senario")
    }

    @NSManaged public var cover: Data?
    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var repeatedTime: Int64
    @NSManaged public var command: NSOrderedSet?

}

// MARK: Generated accessors for command
extension Senario {

    @objc(insertObject:inCommandAtIndex:)
    @NSManaged public func insertIntoCommand(_ value: Command, at idx: Int)

    @objc(removeObjectFromCommandAtIndex:)
    @NSManaged public func removeFromCommand(at idx: Int)

    @objc(insertCommand:atIndexes:)
    @NSManaged public func insertIntoCommand(_ values: [Command], at indexes: NSIndexSet)

    @objc(removeCommandAtIndexes:)
    @NSManaged public func removeFromCommand(at indexes: NSIndexSet)

    @objc(replaceObjectInCommandAtIndex:withObject:)
    @NSManaged public func replaceCommand(at idx: Int, with value: Command)

    @objc(replaceCommandAtIndexes:withCommand:)
    @NSManaged public func replaceCommand(at indexes: NSIndexSet, with values: [Command])

    @objc(addCommandObject:)
    @NSManaged public func addToCommand(_ value: Command)

    @objc(removeCommandObject:)
    @NSManaged public func removeFromCommand(_ value: Command)

    @objc(addCommand:)
    @NSManaged public func addToCommand(_ values: NSOrderedSet)

    @objc(removeCommand:)
    @NSManaged public func removeFromCommand(_ values: NSOrderedSet)

}

extension Senario : Identifiable {

}
