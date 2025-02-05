//
//  CoreDataStack.swift
//  Master
//
//  Created by Sina khanjani on 6/5/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    public var devices: [Device]?

    public var storeContainer: NSPersistentContainer!
    
    var managedContext: NSManagedObjectContext {
        return storeContainer.viewContext
    }
    
    public func fetchDatabase() {
        let deviceFetch: NSFetchRequest<Device> = Device.fetchRequest()
        let devices = try? managedContext.fetch(deviceFetch)
        if let devices = devices {
            self.devices = devices
            print("number of devices In database: \(devices.count)")
            return
        } else {
            self.devices = nil
            print("number of devices In database: nil")
        }
    }

    public func addRadkitModule(internetToken:String,localToken:String,username:String,password:String,port:Int,serial:Int,type:Int,url:String,version:Int,ip:String,wifibssid:String,isStatic: Bool?=false,staticIp: String?=nil, staticPort: String?=nil, inputs: [InputStatus]? = nil,isBossDevice: Bool = false, bridgeDeviceSerial: Int?=nil, escape: ((_ status: Status,_ device: Device?) -> Void)?) {
        if !url.hasSuffix("imaxbms.com") && !isBossDevice {
            escape?(.failed,nil)
            return
        }

        if let devices = self.devices {
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            if index != nil {
                print("the device is already added to database")
                escape?(.failed,nil)
            } else {
                //add new device
                guard let deviceType = DeviceType.init(rawValue: type) else { escape?(.failed,nil); return }
                guard DeviceType.allCases.contains(deviceType) else {  escape?(.failed,nil); return }
                let device = Device(context: managedContext)
                device.isStatic = isStatic ?? false
                device.staticIP = staticIp
                device.staticPort = staticPort
                device.type = Int64(type)
                device.serial = Int64(serial)
                device.version = Int64(version)
                device.url = url
                device.port = Int64(port)
                device.username = username
                device.password = password
                device.localToken = localToken
                device.internetToken = internetToken
                device.ip = ip
                device.isLock = false
                device.wifibssid = wifibssid
                device.isBossDevice = isBossDevice
                if let bridgeDeviceSerial = bridgeDeviceSerial {
                    device.bridgeDeviceSerial = Int64(bridgeDeviceSerial)
                }
                for i in 0..<16 {
                    addRelay(device: device, name: String(i+0))
                }
                if type == 08 || type == 10 || type == 12 {
                    if let inputs = inputs {
                        if let inputStatus = device.inputStatus?.mutableCopy() as? NSMutableOrderedSet {
                            inputStatus.addObjects(from: inputs)
                            device.inputStatus = inputStatus
                        }
                    } else {
                        if let inputStatus = device.inputStatus?.mutableCopy() as? NSMutableOrderedSet {
                            for _ in 0..<16 {
                                let item = InputStatus(context: managedContext)
                                item.status = false
                                inputStatus.add(item)
                            }
                            device.inputStatus = inputStatus
                        }
                    }
                }
                self.devices!.append(device)
                print("New device is added to database.")
                escape?(.deviceAdded,device)
            }
        }
    }
    
    func addRelay(device:Device,name:String) {
        if let relays = device.relays?.mutableCopy() as? NSMutableOrderedSet {
            let relay = Relay(context: managedContext)
            relay.digit = 0
            relay.name = name
            relays.add(relay)
            device.relays = relays
        }
    }
    
    func updateBridgeDeviceSerial(serial: Int64, device: Device) {
        device.bridgeDeviceSerial = serial
        saveContext()
        CoreDataStack.shared.fetchDatabase()
    }
    
    func updateIPInDatabaseModules(serial:Int,ip:String) -> (Status,Device?) {
        if let devices = devices {
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            if let index = index {
                let lastIp = devices[index].ip
                guard lastIp != ip else { return (.failed,nil) }
                devices[index].ip = ip
                print("device serial number: \(serial) ip is now updated...")
                self.devices![index].ip = ip
//                saveContext()
//                self.fetchDatabase()
                return (.changedIP,devices[index])
            } else {
                return (.failed,nil)
            }
        }
        return (.failed,nil)
    }
    
    func updateTokenInDatabaseModules(localToken:String,internetToken:String,serial:Int) {
        if let devices = devices {
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == Int64(serial) {
                    return true
                }
                return false
            }
            if let index = index {
                let lastLocalToken = devices[index].localToken!
                let lastInternetToken = devices[index].internetToken!
                if lastLocalToken == localToken && lastInternetToken == internetToken {
                    return
                }
                devices[index].internetToken = internetToken
                devices[index].localToken = localToken
                print("device tokens is now updated...")
                self.devices![index].internetToken = internetToken
                self.devices![index].localToken = localToken
//                saveContext()
//                self.fetchDatabase()
            }
        }
    }
    
    public func deleteRadkitModule(device: Device) {
        NWSocketConnection.instance.disableAndRemoveModule(device: device)
        managedContext.delete(device)
        saveContext()
        fetchDatabase()
        print("device serial : \(device.serial) is removed from database.)")
        
    }
    
    func saveContext() {
        guard managedContext.hasChanges else { return }
        try? managedContext.save()

//        do {
//            try managedContext.save()
//        } catch let error as NSError {
//            print("Unresolved error \(error), \(error.userInfo)")
//        }
    }
}

extension CoreDataStack {
    func fetchRoomsInDatabase() -> [Room]? {
        let roomsFetch: NSFetchRequest<Room> = Room.fetchRequest()
        let rooms = try? managedContext.fetch(roomsFetch)
        if let rooms = rooms {
            print("number of rooms In database: \(rooms.count)")
            return rooms
        }
        return nil
    }
    
    func fetchEquipments() -> [Equipment]? {
        let equipmentFetch: NSFetchRequest<Equipment> = Equipment.fetchRequest()
        let equipment = try? managedContext.fetch(equipmentFetch)

        return equipment
    }
    
    func updateEquipment(cover: Data, eq: Equipment) {
        eq.image = cover
        saveContext()
    }
    
    func updateEquipment(name: String, eq: Equipment) {
        eq.name = name
        saveContext()
    }
    
    func fetchEquipmentIn(theRoom room:Room) -> [Equipment]? {
        var equipments = [Equipment]()
        room.equipments?.forEach({ (equipment) in
            if let equ = equipment as? Equipment {
                equipments.append(equ)
            }
        })
        return equipments
    }

    func fetchEQDevicesInEquipment(equipment:Equipment) -> [EQDevice]? {
        var eqDevices = [EQDevice]()
        equipment.eqDevice?.forEach({ (anyEqDevice) in
            if let eqDevice = anyEqDevice as? EQDevice {
                eqDevices.append(eqDevice)
            }
        })
        return eqDevices
    }
    
    func fetchEQRelaysIn(equipmentEQDevice:EQDevice) -> [EQRely]? {
        var relays = [EQRely]()
        equipmentEQDevice.eqRelays?.forEach({ (anyEQRel) in
            if let eqRely = anyEQRel as? EQRely {
                relays.append(eqRely)
            }
        })
        return relays
    }
    
    func fetchEqRelaysInAllEQDevices(equipment:Equipment) -> [EQRely] {
        var eqRelays = [EQRely]()
        equipment.eqDevice?.forEach({ (eqsAny) in
            if let eqDevice = eqsAny as? EQDevice {
                eqDevice.eqRelays?.forEach({ (eqsRAny) in
                    if let eqRely = eqsRAny as? EQRely {
                        eqRelays.append(eqRely)
                    }
                })
            }
        })
        return eqRelays
    }
    
    func updateEQRelay(cover: Data, eqRelay: EQRely) {
        eqRelay.cover = cover
        saveContext()
    }
    
    public func addRoomInDatabase(roomImage image: Data?, roomName name:String) -> Room? {
        do {
            let room = Room(context: managedContext)
            if let rooms = self.fetchRoomsInDatabase(), rooms.count != 0  {
                room.id = Int64(arc4random())//Int64(rooms.count)
            } else {
                room.id = Int64(arc4random())
            }
            if let image = image {
                room.image = image
            } else {
                room.image = UIImage(named: "home_back")?.pngData()
            }
            room.name = name

            try managedContext.save()
            print("New room is added to database.")

            return room
        } catch let error as NSError {
            print("add room error: \(error) description: \(error.userInfo)")
            return nil
        }
    }
    
    func updateImageForRoom_1(forRoom room:Room,image:Data) {
        if let rooms = self.fetchRoomsInDatabase() {
            let index = rooms.lastIndex { (dat) -> Bool in
                if dat.id == room.id {
                    return true
                }
                return false
            }
            if let index = index {
                rooms[index].image = image
                saveContext()
            }
        }
    }
    
    func updateImageForRoom_2(inRoom room:Room,image:Data) {
        room.image = image
        saveContext()
    }
    
    func removeRoomInDatabase(room:Room) {
        if let equipments = self.fetchEquipmentIn(theRoom: room) {
            equipments.forEach { eq in
                managedContext.delete(eq)
            }
        }
        managedContext.delete(room)
        saveContext()
        print("Room is now removed from database.")
    }
    
    func addEquipment(addToRoom:Room,image:Data,name:String,type:Int64, isShortcut: Bool, senarioId: Int) -> Equipment? {
        if let rooms = fetchRoomsInDatabase() {
            do {
                let index = rooms.lastIndex { (dat) -> Bool in
                    if dat.id == addToRoom.id {
                        return true
                    }
                    return false
                }
                if let index = index {
                    if let equipments = addToRoom.equipments?.mutableCopy() as? NSMutableOrderedSet {
                        let equipment = Equipment(context: managedContext)
                        equipment.id = Int64(arc4random())
                        equipment.image = image
                        equipment.name = name
                        equipment.type = type
                        equipment.isShortcut = isShortcut
                        equipment.senarioId = Int64(senarioId)
                        equipments.add(equipment)
                        rooms[index].equipments = equipments
                        try managedContext.save()
                        
                        return equipment
                    }
                }
            } catch {
                return nil
                print(error)
            }
        }
        return nil
    }
    
    func updateEquipment_1(room:Room,equipmentId:Int64,image:Data?,name:String?) {
        if let equipments = self.fetchEquipmentIn(theRoom: room) {
            let index = equipments.lastIndex { (dat) -> Bool in
                if dat.id == equipmentId {
                    return true
                }
                return false
            }
            if let index = index {
                if let image = image {
                    equipments[index].image = image
                }
                if let name = name {
                    equipments[index].name = name
                }
                saveContext()
            }
        }
    }
    
    func updateEquipment_2(equipment:Equipment,image:Data?,name:String?) {
        if let image = image {
            equipment.image = image
        }
        if let name = name {
            equipment.name = name
        }
        saveContext()
    }
    
    
    func deleteEquipmentInDatabase(equipment:Equipment) {
        managedContext.delete(equipment)
        saveContext()
    }
    
    func addEQDeviceWithEQRelayToEquipment(addToequipment: Equipment, device: Device, digitsIndex: [Int64],data:Data?=nil,isSwitchSenario:Bool = false) {
        do {
            if let eqDevices = addToequipment.eqDevice?.mutableCopy() as? NSMutableOrderedSet {
                guard let eqdevs = fetchEQDevicesInEquipment(equipment: addToequipment) else { return }
                let index = eqdevs.lastIndex { (dat) -> Bool in
                    if dat.serial == device.serial {
                        return true
                    }
                    return false
                }
                if let index = index {
                    if let eqDev = eqDevices[index] as? EQDevice {
                        addDigits(eqDevice: eqDev, digits: digitsIndex, data: data, isSwitchSenario: isSwitchSenario, equipment: addToequipment)
                        try managedContext.save()
                    }
                } else {
                    let newEQDevice = EQDevice(context: managedContext)
                    newEQDevice.type = device.type
                    newEQDevice.serial = device.serial
                    self.addDigits(eqDevice: newEQDevice, digits: digitsIndex, data: data, isSwitchSenario: isSwitchSenario, equipment: addToequipment)
                    eqDevices.add(newEQDevice)
                    addToequipment.eqDevice = eqDevices
                    try managedContext.save()
                }
            }
        } catch {
            print(error)
        }
    }
    
    func findRealDeviceInEquipment(equipmentEQDevice:EQDevice) -> Device? {
        if let devices = self.devices {
            let index = devices.lastIndex { (dat) -> Bool in
                if dat.serial == equipmentEQDevice.serial {
                    return true
                }
                return false
            }
            if let index = index {
                return devices[index]
            }
        }
        return nil
    }
    
    func findEQDeviceInDevice(device:Device?,equipment: Equipment?) -> EQDevice? {
        guard let equipment = equipment else { return nil }
        guard let device = device else { return nil }
        if let eqDevices = self.fetchEQDevicesInEquipment(equipment: equipment) {
            let index = eqDevices.lastIndex { (dat) -> Bool in
                if dat.serial == device.serial {
                    return true
                }
                return false
            }
            if let index = index {
                return eqDevices[index]
            }
        }
        return nil
    }
    
    func findBitsEqualToEQDevicesDatabase(equipmentEQDevice:EQDevice,bits:[Data.Bit]) -> [Int] {
        var ints = [Int]()
        let Intige64Bits = bits.map { Int64($0.description)! }
        if let eqRelays = self.fetchEQRelaysIn(equipmentEQDevice: equipmentEQDevice) {
            for eqRelay in eqRelays {
                let bit = Intige64Bits[Int(eqRelay.digit)]
                ints.append(Int(bit))
            }
        }
        return ints
    }
    
    func removeEQRelayInDatabse(eqRelay:EQRely) {
        managedContext.delete(eqRelay)
        saveContext()
    }
    
    func updateEQRelayName(eqRelay: EQRely ,name: String) {
        eqRelay.name = name
        saveContext()
    }
    
    private func addDigits(eqDevice:EQDevice,digits: [Int64],data:Data?,isSwitchSenario:Bool = false, equipment: Equipment) {
        var items = [EQRely]()
        for (_,digit) in digits.enumerated() {
            let relay = EQRely(context: managedContext)
            relay.digit = digit
            relay.isContinual = false
            relay.state = nil
            relay.data = data
            let eqDeviceType = eqDevice.type
            switch eqDeviceType {
            case 04:
                relay.name = "C-" + String(digit+1)
            case 09:
                relay.name = "C-" + String(digit+1)
            case 05:
                relay.name = "T-" + String(digit+1)
            case 03:
                relay.name = nil
            default:
                if isSwitchSenario {
                    relay.name = "sc"
                } else {
                    relay.name = String(digit+1)
                }
            }
            if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
                if deviceType == .inputStatus {
                    if digit <= 11 {
                        relay.name = String("I-\(digit+1)")
                    } else {
                        relay.name = String("SC-\(digit-11)")
                    }
                }
            }
            
            items.append(relay)
        }
        if let relays = eqDevice.eqRelays?.mutableCopy() as? NSMutableOrderedSet {
            relays.addObjects(from: items)
            eqDevice.eqRelays = relays
        }
    }
    
    public func clearDeepObjectEntity(_ entity: String) {
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
        } catch {
            print ("There was an error")
        }
    }
    
    public func ResetCoreData(completion: @escaping (_ status: Bool) -> Void) {
        let storeContainer = self.storeContainer.persistentStoreCoordinator
        for store in storeContainer.persistentStores {
            try? storeContainer.destroyPersistentStore(at: store.url!, ofType: store.type, options: nil)
        }
        let container = NSPersistentContainer(name: "RadKit_Module")
        self.storeContainer = container
        container.loadPersistentStores {
            (storeDescription, error) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}


extension CoreDataStack {
    // Senario
    public func fetchSenarios() -> [Senario] {
        var senarios = [Senario]()
        let objectFetch: NSFetchRequest<Senario> = Senario.fetchRequest()
        let items = try? managedContext.fetch(objectFetch)
        if let items = items {
            print("number of senario in database: \(items.count)")
            senarios = items
        }
        return senarios
    }
    
    public func addNewSenario(name:String, repeatedTime: Int, oldId: Int?=nil ,comepletion: ((_ senario: Senario?) -> Void)?) -> Senario? {
        do {
            let senario = Senario(context: managedContext)
            if let oldId = oldId {
                senario.id = Int64(oldId)
            } else {
                senario.id = Int64(arc4random())
            }
            senario.name = name
            senario.repeatedTime = Int64(repeatedTime)
            try managedContext.save()
            print("New senario is added to database.")
            comepletion?(senario)
            return senario
        } catch let error as NSError {
            print("Fetch error: \(error) description: \(error.userInfo)")
            comepletion?(nil)
            return nil
        }
    }
    
    public func changeSenario(_ senario: Senario,_ name:String, repeatedTime: Int? = nil) {
        senario.name = name
        if let repeatedTime = repeatedTime {
            senario.repeatedTime = Int64(repeatedTime)
        }
        saveContext()
    }
    
    func updateSenario(cover: Data, senario: Senario) {
        senario.cover = cover
        saveContext()
    }
    
    public func removeSenario(_ senario:Senario) {
        managedContext.delete(senario)
        saveContext()
    }
    
    // Command
    public func fetchCommandOn(senario: Senario) -> [Command] {
        var commands = [Command]()
        senario.command?.forEach({ (command) in
            if let command = command as? Command {
                commands.append(command)
            }
        })
        return commands
    }
    
    public func addCommandTo(senario: Senario,deviceSerial:Int64,deviceType:Int64,deviceName:String,bytes: [UInt8]) {
        do {
            if let commands = senario.command?.mutableCopy() as? NSMutableOrderedSet {
                let newCommand = Command(context: managedContext)
                newCommand.deviceName = deviceName
                newCommand.deviceType = deviceType
                newCommand.deviceSerial = deviceSerial
                var inputBytes: [UInt8] = bytes
                let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                let data = Data.init(referencing: nsdata)
                newCommand.sendData = data
                newCommand.time = 0.5
                commands.add(newCommand)
                senario.command = commands
                try managedContext.save()
            }
        } catch {
            print(error)
        }
    }
    
    public func updateCommandTo(deviceSerial:Int64,deviceType:Int64,deviceName:String,bytes: [UInt8], command: Command) {
        command.deviceName = deviceName
        command.deviceType = deviceType
        command.deviceSerial = deviceSerial
        var inputBytes: [UInt8] = bytes
        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
        let data = Data.init(referencing: nsdata)
        command.sendData = data
        saveContext()
    }
    
    public func changeTimeFor(command: Command,_ time: Double) {
        command.time = time
        saveContext()
    }
}

// InputStatus
extension CoreDataStack {
    public func fetchInputs(device: Device) -> [InputStatus] {
        var inputs = [InputStatus]()
        device.inputStatus?.forEach({ (input) in
            if let input = input as? InputStatus {
                inputs.append(input)
            }
        })
        return inputs
    }
    
    public func changeInputStatus(name to: String, for input: InputStatus) {
        input.name = to
        saveContext()
    }
    
    public func updateInputStatusRecords(items: [InputStatus], device: Device) {
        if let inputStatus = device.inputStatus?.mutableCopy() as? NSMutableOrderedSet {
            for item in items {
                inputStatus.add(item)
            }
            device.inputStatus = inputStatus
        }
        saveContext()
    }
}
