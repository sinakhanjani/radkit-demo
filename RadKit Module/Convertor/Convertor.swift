//
//  Convertor.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/9/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import Foundation
import Sync
import CoreData

class Backup {
    
    var arrayDicts = [String:Any]()
    ///Use this for export data
    init() {
        
    }
    
    ///Use this for import data
    init(dict: [String:Any]) {
        self.arrayDicts = dict
    }
    
    static public func cleanAll(completion: @escaping (_ result: Bool) -> Void) {
//        CoreDataStack.shared.devices?.removeAll()
//        // delete all database.
//        CoreDataStack.shared.clearDeepObjectEntity("Relay")
//        CoreDataStack.shared.clearDeepObjectEntity("InputStatus")
//        CoreDataStack.shared.clearDeepObjectEntity("Device")
//        CoreDataStack.shared.clearDeepObjectEntity("Command")
//        CoreDataStack.shared.clearDeepObjectEntity("EQDevice")
//        CoreDataStack.shared.clearDeepObjectEntity("EQRely")
//        CoreDataStack.shared.clearDeepObjectEntity("Equipment")
//        CoreDataStack.shared.clearDeepObjectEntity("Room")
//        CoreDataStack.shared.clearDeepObjectEntity("Senario")
//        CoreDataStack.shared.fetchDatabase()
        
        CoreDataStack.shared.ResetCoreData { status in
            print("KHANJANI \(status)")
            CoreDataStack.shared.fetchDatabase()
            if status {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func importToDB() {
        Backup.cleanAll { [weak self] result in
            guard let self = self else { return }
            if result {
                //DeviceImport
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    let isAdminMode = (self.arrayDicts["isAdminMode"] as? Int ?? 0) == 0 ? false:true
                    Password.shared.adminBackupModel = isAdminMode
                    if isAdminMode {
                        Password.shared.adminMode = false
                    }
                    if let devices = self.arrayDicts["devices"] as? [[String:Any]] {
                        devices.forEach { (device) in
                            var inputStatusArray = [InputStatus]()
                            if let arrayInputDics = device["inputStatus"] as? [[String:Any]] {
                                for inputDict in arrayInputDics {
                                    let input = InputStatus(context: CoreDataStack.shared.managedContext)
                                    input.name = inputDict["name"] as? String
                                    input.status = (inputDict["status"] as? Int ?? 0) == 0 ? false:true
                                    inputStatusArray.append(input)
                                }
                            }
                            CoreDataStack.shared.addRadkitModule(internetToken: device["internetToken"] as? String ?? "", localToken: device["localToken"] as? String ?? "", username: device["username"] as? String ?? "", password: device["password"] as? String ?? "", port: device["port"] as? Int ?? 0, serial: device["serial"] as? Int ?? 0, type: device["type"] as? Int ?? 0, url: device["url"] as? String ?? "", version: device["version"] as? Int ?? 0, ip: device["ip"] as? String ?? "", wifibssid: device["wifibssid"] as? String ?? "",isStatic: (device["isStatic"] as? Int ?? 0) == 0 ? false:true,staticIp: device["staticIP"] as? String ?? "", staticPort: device["staticPort"] as? String ?? "", inputs: inputStatusArray.isEmpty ? nil:inputStatusArray, isBossDevice: (device["isBossDevice"] as? Int ?? 0) == 0 ? false:true, bridgeDeviceSerial: device["bridgeDeviceSerial"] as? Int ?? 0, escape: nil)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.0) {
                        if let rooms = self.arrayDicts["rooms"] as? [[String:Any]] {
                            rooms.forEach { (roomDic) in
                                if let room = CoreDataStack.shared.addRoomInDatabase(roomImage: nil, roomName: roomDic["name"] as! String) {
                                    if let equipmentsDic = roomDic["equipments"] as? [[String:Any]] {
                                        equipmentsDic.forEach { (equipmentDict) in
                                            let img = UIImage.init(named: DeviceType.init(rawValue: equipmentDict["type"] as! Int)!.imagename())!.pngData()!
                                            let equipment = CoreDataStack.shared.addEquipment(addToRoom: room, image: img, name: equipmentDict["name"] as! String, type: Int64(equipmentDict["type"] as! Int), isShortcut: (equipmentDict["isShortcut"] as? Int ?? 0) == 0 ? false:true, senarioId: (equipmentDict["senarioId"] as? Int ?? 0))!
                                            if let devicesDict = equipmentDict["devices"] as? [[String:Any]] {
                                                devicesDict.forEach { (deviceDict) in
                                                    let device = EQDevice(context: CoreDataStack.shared.managedContext)
                                                    device.name = deviceDict["name"] as? String ?? "no-name"
                                                    device.type = Int64(deviceDict["type"] as! Int)
                                                    device.serial = Int64(deviceDict["serial"] as! Int)
                                                    equipment.addToEqDevice(device)
                                                    if let relaysDict = deviceDict["relays"] as? [[String:Any]] {
                                                        relaysDict.forEach { (relayDict) in
                                                            let relay = EQRely(context: CoreDataStack.shared.managedContext)
                                                            relay.digit = Int64(relayDict["digit"] as? Int ?? 0)
                                                            relay.name2 = relayDict["name2"] as? String
                                                            relay.name =  relayDict["name"] as? String
                                                            relay.name5 =  relayDict["name5"] as? String
                                                            relay.name4 =  relayDict["name4"] as? String
                                                            relay.name3 = relayDict["name3"] as? String
                                                            relay.name6 = relayDict["name6"] as? String
                                                            relay.state = (relayDict["state"] as? Int ?? 0) == 0 ? false:true
                                                            relay.isContinual = (relayDict["isContinual"] as? Int ?? 0) == 0 ? false:true
                                                            relay.data = NWSocketConnection.ToData(input: relayDict["data"] as? [Int])
                                                            relay.data4 = NWSocketConnection.ToData(input: relayDict["data4"] as? [Int])
                                                            relay.data5 = NWSocketConnection.ToData(input: relayDict["data5"] as? [Int])
                                                            relay.data2 = NWSocketConnection.ToData(input: relayDict["data2"] as? [Int])
                                                            relay.data6 = NWSocketConnection.ToData(input: relayDict["data6"] as? [Int])
                                                            relay.data3 = NWSocketConnection.ToData(input: relayDict["data3"] as? [Int])
                                                            device.addToEqRelays(relay)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.0) {
                            if let senarios = self.arrayDicts["senario"] as? [[String:Any]] {
                                senarios.forEach { (senarioDict) in
                                    if let senario = CoreDataStack.shared.addNewSenario(name: senarioDict["name"] as? String ?? "", repeatedTime: senarioDict["repeatedTime"] as? Int ?? 0, oldId: senarioDict["id"] as? Int, comepletion: nil) {
                                        if let commandsDict = senarioDict["commands"] as? [[String:Any]] {
                                            commandsDict.forEach { (commandDict) in
                                                let command = Command.init(context: CoreDataStack.shared.managedContext)
                                                command.deviceName = commandDict["name"] as? String
                                                command.deviceType = Int64(commandDict["deviceType"] as? Int ?? 0)
                                                command.time = Double(commandDict["time"] as? Double ?? 0.0)
                                                command.deviceSerial = Int64(commandDict["deviceSerial"] as? Int ?? 0)
                                                command.sendData = NWSocketConnection.ToData(input: commandDict["sendData"] as? [Int])
                                                senario.addToCommand(command)
                                                }
                                            }
                                    }
                                }
                            }
                            CoreDataStack.shared.saveContext()
                        }
                    }
                }
            }
        }
    }
    
    func exportFromDB() {
        arrayDicts.removeAll()
        //DeviceExport
        deviceExport()
        //RoomsExport
        roomExport()
        //Senario
        senarioExport()
        arrayDicts.updateValue(Password.shared.adminBackupModel, forKey: "isAdminMode")

        //Print
        arrayDicts.printJson()
    }
    
    private func senarioExport() {
        let senarios = CoreDataStack.shared.fetchSenarios()
        var arraysenarios = [[String:Any]]()
        senarios.forEach { (senario) in
            var senariosDict = expand(senario)
            // commands
            let commands = senario.command?.array as? [Command] ?? []
            var arrayCommnadsDict = [[String:Any]]()
            commands.forEach { (command) in
                var commandDict = expand(command)
                for (key,_) in commandDict {
                    if let data = commandDict[key] as? Data {
                        commandDict.updateValue(data.map(\.byteSwapped).map {Int($0)}, forKey: key)
                    }
                }
                arrayCommnadsDict.append(commandDict)
            }
            senariosDict.updateValue(arrayCommnadsDict, forKey: "commands")
            senariosDict.removeValue(forKey: "cover")
            arraysenarios.append(senariosDict)
        }
        arrayDicts.updateValue(arraysenarios, forKey: "senario")
    }
    
    private func deviceExport() {
        if let devices = CoreDataStack.shared.devices {
            var arrayDevices = [[String:Any]]()
            devices.forEach { (device) in
                var devicesDict = expand(device)
                devicesDict.removeValue(forKey: "requestKey")
                devicesDict.removeValue(forKey: "connectionType")
                devicesDict.removeValue(forKey: "name")
                if let inputStatus = device.inputStatus?.array as? [InputStatus] {
                    var arrayInputStatus = [[String:Any]]()
                    inputStatus.forEach { input in
                        let expandInput = expand(input)
                        arrayInputStatus.append(expandInput)
                    }
                    devicesDict.updateValue(arrayInputStatus, forKey: "inputStatus")
                }
                arrayDevices.append(devicesDict)
            }
            arrayDicts.updateValue(arrayDevices, forKey: "devices")
            print(arrayDicts)
        }
    }
    
    private func roomExport() {
        if let rooms = CoreDataStack.shared.fetchRoomsInDatabase() {
            var arrayRooms = [[String:Any]]()
            rooms.forEach { (room) in
                let modelKeys = ["name","id"]
                let modelDict = room.dictionaryWithValues(forKeys: modelKeys)
                var roomsDict = modelDict
                if let equipments = room.equipments?.array as? [Equipment] {
                    var arrayEquipments = [[String:Any]]()
                    equipments.forEach { (equipment) in
                        let modelKeys2 = ["name","type","id","senarioId", "isShortcut"]
                        let modelDict2 = equipment.dictionaryWithValues(forKeys: modelKeys2)
                        var equipmentDict = modelDict2
                        if let devices = equipment.eqDevice?.array as? [EQDevice] {
                            var arrayDevices = [[String:Any]]()
                            devices.forEach { (device) in
                                var devicesDict = expand(device)
                                devicesDict.removeValue(forKey: "name")
                                if let relays = device.eqRelays?.array as? [EQRely] {
                                    var arrayRelays = [[String:Any]]()
                                    relays.forEach { (relay) in
                                        var relaysDict = expand(relay)
                                        for (key,_) in relaysDict {
                                            if let data = relaysDict[key] as? Data {
                                                relaysDict.updateValue(data.map(\.byteSwapped).map {Int($0)}, forKey: key)
                                            }
                                        }
                                        arrayRelays.append(relaysDict)
                                    }
                                    devicesDict.updateValue(arrayRelays, forKey: "relays")
                                }
                                arrayDevices.append(devicesDict)
                            }
                            equipmentDict.updateValue(arrayDevices, forKey: "devices")
                        }
                        arrayEquipments.append(equipmentDict)
                        roomsDict.updateValue(arrayEquipments, forKey: "equipments")
                    }
                }
                arrayRooms.append(roomsDict)
            }
            arrayDicts.updateValue(arrayRooms, forKey: "rooms")
        }
    }
    
    private func expand<T: NSManagedObject>(_ model: T) -> [String:Any] {
        let modelKeys = Array(model.entity.attributesByName.keys)
        let modelDict = model.dictionaryWithValues(forKeys: modelKeys)

        return modelDict
    }
    
    private func createArrayDictionary<T:NSManagedObject>(models:[T]) -> [[String:Any]] {
        var arraymodels = [[String:Any]]()
        
        models.forEach { (model) in
            let modelsDict = expand(model)
            arraymodels.append(modelsDict)
        }
        
        return arraymodels
    }
}

