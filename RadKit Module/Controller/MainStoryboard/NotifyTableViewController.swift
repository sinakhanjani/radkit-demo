//
//  NotifyTableViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 6/24/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import UIKit

class NotifyTableViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    
    @IBOutlet weak var pushSwitch: UISwitch!
    @IBOutlet weak var smsSwitch: UISwitch!

    
    var device: Device?
    var res: RadkitNotification?
    var items: [BitCalculator] = [] {
        willSet {
            self.res?.selectedInputs = BitCalculator.convert(bits32: newValue)
        }
    }
    var names: [String] = [] {
        willSet {
            self.res?.inputNames = newValue.description //****
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetch()
    }
    
    func fetch() {
        guard let serial = device?.serial else {
            return
        }
        WebAPI.instance.getNotifications(sn: "\(serial)") { [weak self] res in
            guard let self = self else { return }
            self.res = res
            /// for first time if notification not found is here ::
            if res == nil {
                var nameArray = [String]()
                if let device = self.device {
                    if let deviceType = DeviceType(rawValue: Int(device.type)) {
                        if case .remotes = deviceType {
                            for index in 0..<22 {
                                if index == 0 {
                                    nameArray.append("RESERVED")
                                } else {
                                    nameArray.append("Event \(index)")
                                }
                            }
                        }
                        if case .switch12_3 = deviceType {
                            for index in 0..<17 {
                                if index > 12 {
                                    nameArray.append("Scenario \(index-12)")
                                } else {
                                    if index == 0 {
                                        nameArray.append("RESERVED")
                                    } else {
                                        nameArray.append("Input \(index)")
                                    }
                                }
                            }
                        }
                        if case .switch12_sim_0 = deviceType {
                            for index in 0..<17 {
                                if index > 12 {
                                    nameArray.append("Scenario \(index-12)")
                                } else {
                                    if index == 0 {
                                        nameArray.append("RESERVED")
                                    } else {
                                        nameArray.append("Input \(index)")
                                    }
                                }
                            }
                        }
                    }
                }
                guard let device = self.device else { return }
                WebAPI.instance.postNotification(serial: "\(device.serial)", intToken: "\(device.internetToken ?? "")", selectedInputs: 0, inputsName: nameArray.description, isPushEnable: self.pushSwitch.isOn, isSMSEnable: self.smsSwitch.isOn) { [weak self] notify in
                    guard let self = self else { return }
                    if notify != nil {
                        DispatchQueue.main.async { [weak self] in
                            self?.fetch()
                        }
                    }
                }
                return
            }
            
            if let number = res?.selectedInputs {
                self.items = BitCalculator.toBits(fromByte: number)
                // set names*
                if let names = res?.inputNames {
                    self.names = self.convert(str: names)
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let notif = self.res {
                    self.pushSwitch.isOn = notif.enablePush ?? false
                    self.smsSwitch.isOn = notif.enableSMS ?? false
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func convert(str: String) -> [String] {
        guard let data = str.data(using: .utf8),
              let arrayOfStrings = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] else {
                fatalError()
        }
        
        return arrayOfStrings
    }
    
    @IBAction func agreeButtonTapped() {
        guard let device = device,let res = self.res else { return }
        guard let inputNames = res.inputNames,!inputNames.isEmpty && res.selectedInputs != nil else {
            var nameArray = [String]()
            if let device = self.device {
                if let deviceType = DeviceType(rawValue: Int(device.type)) {
                    if case .remotes = deviceType {
                        for index in 0..<22 {
                            if index == 0 {
                                nameArray.append("RESERVED")
                            } else {
                                nameArray.append("Event \(index)")
                            }
                        }
                    }
                    if case .switch12_3 = deviceType {
                        for index in 0..<17 {
                            if index > 12 {
                                nameArray.append("Scenario \(index-12)")
                            } else {
                                if index == 0 {
                                    nameArray.append("RESERVED")
                                } else {
                                    nameArray.append("Input \(index)")
                                }
                            }
                        }
                    }
                    if case .switch12_sim_0 = deviceType {
                        for index in 0..<17 {
                            if index > 12 {
                                nameArray.append("Scenario \(index-12)")
                            } else {
                                if index == 0 {
                                    nameArray.append("RESERVED")
                                } else {
                                    nameArray.append("Input \(index)")
                                }
                            }
                        }
                    }
                }
            }
            WebAPI.instance.postNotification(serial: "\(device.serial)", intToken: "\(device.internetToken ?? "")", selectedInputs: 0, inputsName: nameArray.description, isPushEnable: pushSwitch.isOn, isSMSEnable: smsSwitch.isOn) {[weak self] notify in
                guard let self = self else { return }
                if notify != nil {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
            return
        }
        self.res?.selectedInputs = BitCalculator.convert(bits32: self.items)
        self.res?.inputNames = names.description //****
        WebAPI.instance.postNotification(serial: "\(device.serial)", intToken: "\(device.internetToken ?? "")", selectedInputs: res.selectedInputs!, inputsName: inputNames, isPushEnable: pushSwitch.isOn, isSMSEnable: smsSwitch.isOn) {[weak self] notify in
            guard let self = self else { return }
            if notify != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    static func create(device: Device) -> NotifyTableViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "NotifyTableViewController") as! NotifyTableViewController
        vc.device = device
        
        return vc
    }
}

extension NotifyTableViewController: UITableViewDelegate, UITableViewDataSource, RadkitTableViewCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.items.isEmpty {
            return 0
        }
        if let type = device?.type {
            if let deviceType = DeviceType(rawValue: Int(type)) {
                if case .remotes = deviceType {
                    return 20
                }
            }
        }
        return 16
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! RadkitTableViewCell
        cell.delegate = self
        if let type = device?.type {
            if let deviceType = DeviceType(rawValue: Int(type)) {
                if case .remotes = deviceType {
                    cell.label_1.text = "Event \(indexPath.item+1)"
                }
                if case .switch12_sim_0 = deviceType {
                    if indexPath.item > 11 {
                        cell.label_1.text = "Scenario \(indexPath.item-11)"
                    } else {
                        cell.label_1.text = "Input \(indexPath.item+1)"
                    }
                }
                if case .switch12_3 = deviceType {
                    if indexPath.item > 11 {
                        cell.label_1.text = "Scenario \(indexPath.item-11)"
                    } else {
                        cell.label_1.text = "Input \(indexPath.item+1)"
                    }
                }
            }
            
            cell.button1.setTitle(self.names[indexPath.item+1], for: .normal)
            cell.switchButton1.isOn = self.items[indexPath.item+1].isOn
        }
        
        return cell
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            if case .began = sender.state {
                self.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder:"Write the name") { [weak self] (name) in
                    if let cell = self?.tableView.cellForRow(at: indexPath) as? RadkitTableViewCell {
                        self?.names[indexPath.item+1] = name
                        cell.button1.setTitle(name, for: .normal)
                    }
                }
            }
        }
    }
    
    func switchButtonValueChanged(sender: UISwitch, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            self.items[indexPath.item+1] = sender.isOn ? .one:.zero
        }
    }
}


// MARK: - RadkitNotification
struct RadkitNotification: Codable {
    let userKey, packageName, fcmID, serialNumber: String?
    let inetToken: String?
    var selectedInputs: Int?
    var inputNames, phoneNumber: String?
    let enablePush, enableSMS: Bool?
    let id: Int?

    enum CodingKeys: String, CodingKey {
        case userKey = "user_key"
        case packageName = "package_name"
        case fcmID = "fcm_id"
        case serialNumber = "serial_number"
        case inetToken = "inet_token"
        case selectedInputs = "selected_inputs"
        case inputNames = "input_names"
        case phoneNumber = "phone_number"
        case enablePush = "enable_push"
        case enableSMS = "enable_sms"
        case id
    }
}

extension NotifyTableViewController {
    enum BitCalculator: UInt8 {
        case zero, one
        
        public var isOn: Bool {
            switch self {
            case .one:
                return true
            case .zero:
                return false
            }
        }
        
        private func asInt() -> Int {
            return (self == .one) ? 1 : 0
        }
        
        static public func toBits(fromByte number: Int) -> [BitCalculator] {
            var byte = UInt32(number)
            var bits = [BitCalculator](repeating: .zero, count: 32)
            
            for i in 0..<32 {
                let currentBit = byte & 0x01
                if currentBit != 0 {
                    bits[i] = .one
                }
                byte >>= 1
            }
            
            return bits
        }
        
        static private func toBytes(bits: [BitCalculator]) -> [UInt8] {
            assert(bits.count % 8 == 0, "Bit array size must be multiple of 8")

            let numBytes = 1 + (bits.count - 1) / 8
            var bytes = [UInt8](repeating : 0, count : numBytes)
            
            for pos in 0 ..< numBytes {
                let val = 128 * bits[8 * pos].asInt() +
                    64 * bits[8 * pos + 1].asInt() +
                    32 * bits[8 * pos + 2].asInt() +
                    16 * bits[8 * pos + 3].asInt() +
                    8 * bits[8 * pos + 4].asInt() +
                    4 * bits[8 * pos + 5].asInt() +
                    2 * bits[8 * pos + 6].asInt() +
                    1 * bits[8 * pos + 7].asInt()
                bytes[pos] = UInt8(val)
            }
            
            return bytes
        }
        
        static public func convert(bits32: [BitCalculator]) -> Int {            
            var bits = bits32
            bits.reverse() // this is for convert than you cab send it to server
            let array = BitCalculator.toBytes(bits: bits)
            var value: UInt32 = 0
            let data = NSData(bytes: array, length: array.count)
            data.getBytes(&value, length: array.count)
            value = UInt32(bigEndian: value)

            return Int(value)
        }
    }
}
