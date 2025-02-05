//
//  SenarioSendDataV2Controller.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/4/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import Foundation

struct SenarioSendDataV2Controller {
    struct SendSenario {
        let command: Command?
        let time: Double
        let deviceSerial: Int64
    }

    static func run(viewController:UIViewController,_ senario: Senario, completion: @escaping (_ dict: [Int64: [UInt8]]?) -> Void) {
        let commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
        guard !commands.isEmpty else {
            viewController.presentIOSAlertWarning(message: "This scenario does not contain any commands") {}
            completion(nil)
            return
        }
        
        //NEW SENARIO SEND Network-146040 [0, 2, 1, 1, 0, 2, 1, 0, 0, 4, 1]
        //NEW SENARIO SEND BOS-1001 [0, 1, 6, 0, 1]
        
        func nullBytes(type: Int64) -> [UInt8] {
            var bytes = [UInt8]()

            if let deviceType = DeviceType.init(rawValue: Int(type)) {
                switch deviceType {
                case .switch1,.switch6_13,.switch6,.switch12_0,.switch12_1,.switch12_2,.switch12_3,.switch12_sim_0,.switch6_14,.switch6_15:
                    bytes = [0,0]
                    break
                case .thermostat:
                    bytes = [0,0,0,0]
                    break
                case .rgbController,.dimmer:
                    bytes = [0,0,0,0,0,0,0,0,0,0,0]
                    break
                case .remotes:
                    bytes = [0]
                    break
                default:
                    break
                }
            }
            
            return bytes
        }
        
        func calculateTime(cm: Command, indx: Int) -> [UInt8] {
            var time: Double = cm.time
            
            if commands.count > indx+1 {
                for command in commands[(indx+1)...] {
                    if command.deviceSerial == cm.deviceSerial {
                        var ft = Int(time*2)
                        let tToBytes = Data(bytes: &ft,
                                            count: MemoryLayout.size(ofValue: ft)).bytes
                        
                        return [UInt8(tToBytes[1]), UInt8(tToBytes[0])]
                    }
                    
                    time += command.time
                }
            }
            
            var ft = Int(time*2)
            let tToBytes = Data(bytes: &ft,
                                count: MemoryLayout.size(ofValue: ft)).bytes
            
            return [UInt8(tToBytes[1]), UInt8(tToBytes[0])]
        }
        
        var dict = [Int64: [UInt8]]()
        var dictCount: [Int64: Int] = [:]

        for (index, command) in commands.enumerated() {
            if var value = dict[command.deviceSerial] {
                // MARK: - Update count of commands in value:
                // change count
                value[1] = UInt8(Int(value[1])+1)
                // MARK: - ADD NEW COMMAND
                if let commandData = command.sendData?.bytes {
                    // add command
                    value.append(contentsOf: commandData)
                    // add time
                    value.append(contentsOf: calculateTime(cm: command, indx: index))
                    // add final data to index value
                    dict[command.deviceSerial] = value
                    dictCount.updateValue(Int(value[1])+1, forKey: command.deviceSerial)
                }
            } else {
                // MARK: - ADD FIRST (NOT NULL)
                // 0 + (Tedad Command), commandData
                if dict.isEmpty {
                    if let commandData = command.sendData?.bytes {
                        // add 0 && command.count
                        var bytes = [UInt8(0), UInt8(1)]
                        // add time * 2 bytes
//                        let time = command.time
//                        var ft = Int(time*2)
//                        let tToBytes = Data(bytes: &ft,
//                                            count: MemoryLayout.size(ofValue: ft)).bytes
//                        print(calculateTime(cm: command, indx: index))
                        bytes.append(contentsOf: commandData)
//                        bytes.append(contentsOf: [UInt8(tToBytes[1]), UInt8(tToBytes[0])])
                        bytes.append(contentsOf: calculateTime(cm: command, indx: index))

                        dict.updateValue(bytes, forKey: command.deviceSerial)
                        dictCount.updateValue(1, forKey: command.deviceSerial)
                    }
                } else {
                    // MARK: - ADD FIRST (NULL)
                    // null parameters
                    var bytes = [UInt8(0), UInt8(2)]
                    // add time
                    let time: Double = commands[0..<index].map(\.time).reduce(0.0) { partialResult, t in
                        return t + partialResult
                    }
                    var ft = Int(time*2)
                    let tToBytes = Data(bytes: &ft,
                                        count: MemoryLayout.size(ofValue: ft)).bytes
                    
                    bytes.append(contentsOf: nullBytes(type: command.deviceType))
                    bytes.append(contentsOf: [UInt8(tToBytes[1]), UInt8(tToBytes[0])])
                    
                    dict.updateValue(bytes, forKey: command.deviceSerial)
                    dictCount.updateValue(1, forKey: command.deviceSerial)

                    // add other commands for first null
                    var secondCommnadBytes = [UInt8]()
                    if let commandData = command.sendData?.bytes {
                        // add command
                        secondCommnadBytes.append(contentsOf: commandData)
                        // add time
                        secondCommnadBytes.append(contentsOf: calculateTime(cm: command, indx: index))
                        // add final data to index value
                        if var value = dict[command.deviceSerial] {
                            value.append(contentsOf: secondCommnadBytes)
                            dict[command.deviceSerial] = value
                            dictCount.updateValue(2, forKey: command.deviceSerial)
                        }
                    }
                }
            }
        }
        if senarioCondition(dict: dict, dictCount: dictCount) {
            print("SCENARIO BYTES: ", dict)
            //146040:  [0, 2, 1, 1, 0, 4, 1, 0, 0, 1]
            //1001:    [0, 2, 0, 0, 0, 4, 2, 1, 0, 2]
            completion(dict)
        } else {
            completion(nil)
        }
    }
    
    static private func senarioCondition(dict: [Int64: [UInt8]], dictCount: [Int64:Int]) -> Bool {
        var go = true
        
        if let devices = CoreDataStack.shared.devices {
            for (deviceSerial) in dict.keys {
                if let device = devices.first(where: { item in
                    item.serial == deviceSerial
                }) {
                    if device.version >= Int64(10) && dictCount[deviceSerial]! <= 21 {
                        go = true
                    } else {
                        go = false
                        return false
                    }
                }
            }
            
            return go
        } else {
            return false
        }
    }
}

