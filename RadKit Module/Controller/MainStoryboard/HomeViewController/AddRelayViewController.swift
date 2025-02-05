//
//  AddRelayViewController.swift
//  Master
//
//  Created by Sina khanjani on 10/1/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit
import DropDown

class AddRelayViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deviceButton: RoundedButton!
    
    private var completion: ((_ selectedIndex: [Int]?,_ device:Device?,_ data: Data?) -> Void)?
    private let deviceDropButton = DropDown()
    
    var dataSource = [Device]()
    var equipment: Equipment?
    var selectedDevice: Device?
    var selectedIndex = [Int]()
    var isDeviceTypeWifi = false
    var type: String = "default"
    var switchSenarioSelectedBits = [Data.Bit](repeating: .zero, count: 16)
    var switchSenarioSituationBits = [Data.Bit](repeating: .zero, count: 16)

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        deviceDropButton.anchorView = deviceButton
        deviceDropButton.bottomOffset = CGPoint(x: 0, y: deviceButton.bounds.height)
        deviceDropButton.textFont = UIFont.persianFont(size: 14.0)
        self.deviceDropButton.selectionAction = { (index, item) in
            self.deviceButton.setTitle(item, for: .normal)
            self.selectedDevice = self.dataSource[index]
            self.selectedIndex = []
            self.collectionView.reloadData()
        }
    }
    
    func updateUI() {
        if self.type == "default" {
            collectionView.allowsMultipleSelection = true
        }
        if let equipment = self.equipment {
            if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
                guard let devices = CoreDataStack.shared.devices else { return }
                switch deviceType {
                case .switch1,.switch6, .switch6_13,.switch6_14,.switch6_15, .switch12_0,.switch12_1,.switch12_2,.switch12_3, .switchSenario, .switch12_sim_0:
                    dataSource = devices.filter { $0.type == Int(01) || $0.type == Int(02) || $0.type == Int(07) || $0.type == Int(08) || $0.type == Int(10) || $0.type == Int(11) || $0.type == Int(12) || $0.type == Int(13) || $0.type == Int(14) || $0.type == Int(15)}
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            if item.isBossDevice {
                                var serial = "\(item.serial)"
                                if serial.count < 6 {
                                    while serial.count < 6 {
                                        serial = "0" + serial
                                    }
                                }
                                
                                return devType.changed() + "\(serial)"
                            } else {
                                return devType.changed() + "\(item.serial)"
                            }
                        }
                        return ""
                    }
                case .dimmer:
                    dataSource = devices.filter { $0.type == Int(09) || $0.type == Int(04) }
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .rgbController:
                    collectionView.allowsMultipleSelection = false
                    dataSource = devices.filter { $0.type == Int(09) || $0.type == Int(04) }
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .thermostat:
                    dataSource = devices.filter { $0.type == Int(05) }
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .remotes,.tv:
                    collectionView.allowsMultipleSelection = false
                    dataSource = devices.filter { $0.type == Int(03) }
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .wifi:
                    collectionView.allowsMultipleSelection = false
                    dataSource = devices.filter { $0.type == Int(03) }
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .ac, .engine, .humidityControl:
                    collectionView.allowsMultipleSelection = false
                    dataSource = devices.filter { $0.type == Int(05) || $0.type == Int(501) || $0.type == Int(502) || $0.type == Int(503)}
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .shortcut:
                    break
                case .inputStatus:
                    dataSource = devices.filter { $0.type == Int(10) || $0.type == Int(12) || $0.type == Int(09) || $0.type == Int(05) || $0.type == Int(04) }
                    deviceDropButton.dataSource = dataSource.map { item in
                        if let devType = DeviceType.init(rawValue: Int(item.type)) {
                            var serial = "\(item.serial)"
                            if serial.count < 6 {
                                while serial.count < 6 {
                                    serial = "0" + serial
                                }
                            }
                            
                            return devType.changed() + "\(serial)"
                        }
                        return ""
                    }
                case .cctv:
                    break
                }
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deviceButtonTapped(_ sender: RoundedButton) {
        deviceDropButton.show()
    }
    
    @IBAction func agreeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            if let device = self.selectedDevice {
                if let equipment = self.equipment {
                    if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
                        if deviceType == .switchSenario {
                            let b1 = Data.bitsToBytes(bits: self.switchSenarioSelectedBits.reversed())
                            let b2 = Data.bitsToBytes(bits: self.switchSenarioSituationBits.reversed())
                            var inputBytes = b2 + b1
                            let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                            let data = Data.init(referencing: nsdata)
                            print("save data: ", data, "bits: ",inputBytes)
                            self.completion?(nil,device,data)
                        } else {
                            if !self.selectedIndex.isEmpty {
                                print(self.selectedIndex)
                                self.completion?(self.selectedIndex,device,nil)
                            }
                        }
                    }
                }
            } else {
                self.completion?(nil,nil,nil)
            }
        }
    }
    
    static func create(equipment: Equipment,completion: ((_ selectedIndex: [Int]?,_ device:Device?,_ data: Data?) -> Void)?) -> UINavigationController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nav = mainStoryboard.instantiateViewController(withIdentifier:
        "AddRelayViewController") as! UINavigationController
        let vc = nav.viewControllers.first as! AddRelayViewController
        vc.equipment = equipment
        vc.completion = completion
        return nav
    }
}

extension AddRelayViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let selectedDevice = self.selectedDevice {
            if let deviceType = DeviceType.init(rawValue: Int(selectedDevice.type)) {
                if let equipment = self.equipment {
                    if let eqDeviceType = DeviceType.init(rawValue: Int(equipment.type)) {
                        if eqDeviceType == .dimmer {
                            return 6
                        }
                        if eqDeviceType == .rgbController {
                            return 2
                        }
                        if eqDeviceType == .remotes {
                            self.selectedIndex.append(0)
                            return 0
                        }
                        if eqDeviceType == .tv {
                            self.selectedIndex.append(0)
                            return 0
                        }
                        if eqDeviceType == .wifi {
                            self.isDeviceTypeWifi = true
                            return 4
                        }
                        if eqDeviceType == .ac {
                            return 2
                        }
                        if eqDeviceType == .engine || eqDeviceType == .humidityControl {
                           return 1
                        }
                        if eqDeviceType == .inputStatus {
                            switch deviceType {
                            case .dimmer: return 4
                            case .rgbController: return 4
                            case .thermostat: return 4
                            default: return 16
                            }
                        }
                    }
                }
                
                return deviceType.channelCount()
            }
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "centerMainCollectionView", for: indexPath) as! RadKitCollectionViewCell
        if self.type == "default" {
            if !isDeviceTypeWifi {
                if let equipment = self.equipment {
                    if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
                        if deviceType == .inputStatus {
                            if indexPath.item <= 11 {
                                cell.button1.setTitle("I-\(indexPath.item+1)", for: .normal)
                            } else {
                                cell.button1.setTitle("SC-\(indexPath.item-11)", for: .normal)
                            }
                        } else {
                            cell.button1.setTitle("\(indexPath.item+1)", for: .normal)
                        }
                    }
                }
            } else {
                var name = ""
                switch indexPath.item {
                case 0:
                    name = "General"
                case 1:
                    name = "TC2-1"
                case 2:
                    name = "TC2-2"
                case 3:
                    name = "TC2-3"
                default:
                    break
                }
                cell.button1.setTitle(name, for: .normal)
            }
            
            if selectedIndex.contains(indexPath.item) {
                cell.imageView1.image = UIImage.init(named: "click_blue")
            } else {
                cell.imageView1.image = UIImage.init(named: "click_none")
            }
        } else {
            // for switchSenarioVC
            cell.button1.setTitle("\(indexPath.item+1)", for: .normal)
            // 0=none 1=green 2=red
            switch cell.tag {
            case 0:
                cell.imageView1.image = UIImage.init(named: "click_none")
                self.switchSenarioSelectedBits[indexPath.item] = .zero
                self.switchSenarioSituationBits[indexPath.item] = .zero
            case 1:
                cell.imageView1.image = UIImage.init(named: "click_green")
                self.switchSenarioSelectedBits[indexPath.item] = .one
            case 2:
                cell.imageView1.image = UIImage.init(named: "click_red")
                self.switchSenarioSelectedBits[indexPath.item] = .one
                self.switchSenarioSituationBits[indexPath.item] = .zero
                
            default:
                break
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? RadKitCollectionViewCell {
            if self.type == "default" {
                self.selectedIndex.append(indexPath.item)
                cell.imageView1.image = UIImage.init(named: "click_blue")
            } else {
                // for switchSenarioVC
                // 0=none 1=green 2=red
                switch cell.tag {
                case 0:
                    cell.tag = 1
                    cell.imageView1.image = UIImage.init(named: "click_green")
                    self.switchSenarioSelectedBits[indexPath.item] = .one
                    self.switchSenarioSituationBits[indexPath.item] = .one
                case 1:
                    cell.tag = 2
                    cell.imageView1.image = UIImage.init(named: "click_red")
                    self.switchSenarioSelectedBits[indexPath.item] = .one
                    self.switchSenarioSituationBits[indexPath.item] = .zero
                case 2:
                    cell.tag = 0
                    cell.imageView1.image = UIImage.init(named: "click_none")
                    self.switchSenarioSelectedBits[indexPath.item] = .zero
                    self.switchSenarioSituationBits[indexPath.item] = .zero
                default:
                    break
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let index = selectedIndex.firstIndex(where: { $0 == indexPath.item }) {
            if let cell = collectionView.cellForItem(at: indexPath) as? RadKitCollectionViewCell {
                cell.imageView1.image = UIImage.init(named: "click_none")
            }
            selectedIndex.remove(at: index)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numberOfColumns: CGFloat = 2
        if UIScreen.main.bounds.width > 320 {
            numberOfColumns = 3
        }
        let spaceBetweenCells: CGFloat = 10
        let padding: CGFloat = 40
        let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns

        return CGSize.init(width: cellDimention, height: cellDimention)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //
    }
}
