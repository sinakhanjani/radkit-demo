//
//  RGBViewController.swift
//  Master
//
//  Created by Sina khanjani on 10/18/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit
import FlexColorPicker

extension RGBViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("RGB",bytes, device!.serial)
        if tag == 1 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
        if tag == 2 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let newColor = UIColor.white
                let hsbColor = newColor.hsbColor
                self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
                self.view.backgroundColor = UIColor.systemGroupedBackground
                self.pickerController.radialHsbPalette?.contentView.layer.borderColor = UIColor.systemBackground.cgColor

            }
        }
        if tag == 3 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
        if tag == 4 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
        if tag == 5 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
        if tag == 6 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
        if tag == 7 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
        if tag == 8 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes,device: device)
        }
        if tag == 1111 && dict?["hearth"] == nil {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }
    }
}

class RGBViewController: UIViewController,ColorPickerDelegate,ConfigAdminRolles {
    func adminChanged() {
        self.admin()
    }
    
    // Senario
    private var completion: ((_ eqRelays: EQRely?,_ rgb:RGB?,_ items:[Int:UInt8]) -> Void)?
    public var isSenario:Bool = false
    var sendRGB:RGB! // pishfarz
    var sendItems: [Int:UInt8]? = [1: UInt8(255), 2: UInt8(255), 3: UInt8(255)] // pishfarz
    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ rgb:RGB?,_ items:[Int:UInt8]) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RGBViewController") as! RGBViewController
        vc.isSenario = true
        vc.equipment = equipment
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.setViewControllers([vc], animated: true)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
        //        navigationController.navigationBar.barTintColor = #colorLiteral(red: 0, green: 0.6947382092, blue: 0.6967663169, alpha: 1)
        vc.completion = completion
        viewController.present(navigationController, animated: true, completion: nil)
    }
    @objc func doneSenarioButtonTapped() {
        if let selectedEqRelay = self.eqRelays {
            completion?(selectedEqRelay[0],sendRGB,sendItems ?? [:])
        } else {
            completion?(nil,nil,[:])
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet var pickerController: ColorPickerController!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var rgbTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var titleBoxView: UIView!
    
    var equipment: Equipment?
    var eqRelays: [EQRely]?
    var type: Int?
    var isMicrophoneEnable:Bool = false
    var updatePallet = 0 {
        willSet {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.2) { [weak self] in
                guard let self = self else { return }
                if newValue == self.updatePallet {
                    print("FINISHED !!!!!!")
                    guard let selectedColor = self.pickerController.radialHsbPalette?.selectedColor else { return }
                    let hsbColor = selectedColor.hsbColor
                    self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
                    guard let eqRelays = self.eqRelays else { return }
                    guard let eqDevice = eqRelays[0].eqDevice else { return }
                    guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                    guard let rgb = selectedColor.rgb() else { return }
                    var items = [Int:UInt8]()
                    if eqRelays[0].digit == 0 {
                        items.updateValue(UInt8(rgb.red), forKey: 1)
                        items.updateValue(UInt8(rgb.green), forKey: 2)
                        items.updateValue(UInt8(rgb.blue), forKey: 3)
                    } else {
                        items.updateValue(UInt8(rgb.red), forKey: 4)
                        items.updateValue(UInt8(rgb.green), forKey: 5)
                        items.updateValue(UInt8(rgb.blue), forKey: 6)
                    }
                    if self.isSenario {
                        self.sendItems = items
                    } else {
                        NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:1,device: device, typeRequest: .directRequest, items: items, isDimmer: false, isDaem: false, rgb: nil) { [weak self] (device, bytes) in
                            guard let self = self else { return }
//                            guard let device = device, let bytes = bytes else { return }
//                            self.setDataToCorrectRelay(bytes: bytes, device: device)
                        }
                    }
                }
            }
        }
    }
    
    var currentSelectedColor: String? = nil {
        willSet {
            if let newValue = newValue {
                if isSenario {
                    let color = UIColor.fromHex(hexString: defaultColors["\(newValue)"]!)
                    guard let eqRelays = self.eqRelays else { return }
                    guard let rgb = color.rgb() else { return }
                    var items = [Int:UInt8]()
                    if eqRelays[0].digit == 0 {
                        items.updateValue(UInt8(rgb.red), forKey: 1)
                        items.updateValue(UInt8(rgb.green), forKey: 2)
                        items.updateValue(UInt8(rgb.blue), forKey: 3)
                    } else {
                        items.updateValue(UInt8(rgb.red), forKey: 4)
                        items.updateValue(UInt8(rgb.green), forKey: 5)
                        items.updateValue(UInt8(rgb.blue), forKey: 6)
                    }
                    if newValue == "D" {
                        let newColor = UIColor.white
                        let hsbColor = newColor.hsbColor
                        self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
                    } else {
                        let hsbColor = color.hsbColor
                        self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
                    }
                    self.sendItems = items
                } else {
                    let color = UIColor.fromHex(hexString: defaultColors["\(newValue)"]!)
                    let hsbColor = color.hsbColor
                    self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
                    self.view.backgroundColor = Constant.Colors.blue
                    self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
                    guard let eqRelays = self.eqRelays else { return }
                    guard let eqDevice = eqRelays[0].eqDevice else { return }
                    guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                    guard let rgb = color.rgb() else { return }
                    var items = [Int:UInt8]()
                    if eqRelays[0].digit == 0 {
                        items.updateValue(UInt8(rgb.red), forKey: 1)
                        items.updateValue(UInt8(rgb.green), forKey: 2)
                        items.updateValue(UInt8(rgb.blue), forKey: 3)
                    } else {
                        items.updateValue(UInt8(rgb.red), forKey: 4)
                        items.updateValue(UInt8(rgb.green), forKey: 5)
                        items.updateValue(UInt8(rgb.blue), forKey: 6)
                    }
                    guard newValue != "D" else {
                        NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:2,device: device, typeRequest: .directRequest, items: items, isDimmer: false, isDaem: false, rgb: nil) { [weak self] (device, bytes) in
//                            guard let self = self else { return }
//                            DispatchQueue.main.async { [weak self] in
//                                guard let self = self else { return }
//                                let newColor = UIColor.white
//                                let hsbColor = newColor.hsbColor
//                                self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
//                                self.view.backgroundColor = UIColor.systemGroupedBackground
//                            }
                        }
                        return
                    }
                    NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:3,device: device, typeRequest: .directRequest, items: items, isDimmer: false, isDaem: false, rgb: nil) { [weak self] (device, bytes) in
                        guard let self = self else { return }
//                        guard let device = device, let bytes = bytes else { return }
//                        self.setDataToCorrectRelay(bytes: bytes, device: device)
                    }
                }
            }
        }
    }
    
    @objc func lognGestureTapped(_ sender: UILongPressGestureRecognizer) {
        if isSenario {
            
        } else {
            if let items = self.eqRelays {
                switch sender.state {
                case .possible:
                    break
                case .began:
                    if Password.shared.adminMode {
                        self.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                            guard let self = self else { return }
                            CoreDataStack.shared.updateEQRelayName(eqRelay: items[0], name: name)
                            self.rgbTitleLabel.text = (items[0].name ?? "")
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    var defaultColors = ["R":"FF0000",
                         "G":"00FF00",
                         "B":"0000FF",
                         "C":"00FFFF",
                         "P":"FF00FF",
                         "Y":"FFFF00",
                         "W":"FFFFFF",
                         "D":"000000"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        pickerController.delegate = self
        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))
            //            rightfBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(backSenarioButtonTapped))
            //            leftBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen
            self.fetchAllEQRelayInEquipment()
            if let equipment = self.equipment {
                self.title = equipment.name
            }
            self.brightnessSlider.setValue(100, animated: true)
            if let eqRelays = eqRelays {
                guard !eqRelays.isEmpty else { return }
                self.sendRGB = RGB(speed: nil, light: 100, type: Int(eqRelays[0].digit+1), effectType: nil)
            }
        } else {
            backBarButtonAttribute(color: .white, name: "")
            if let equipment = self.equipment {
                self.title = equipment.name
            }
            self.fetchAllEQRelayInEquipment()
            let touch = UILongPressGestureRecognizer.init(target: self, action: #selector(lognGestureTapped(_:)))
            self.titleBoxView.addGestureRecognizer(touch)
            
            self.pickerController.radialHsbPalette?.contentView.layer.borderColor = UIColor.systemBackground.cgColor
            self.pickerController.radialHsbPalette?.contentView.layer.borderWidth = 6
            self.pickerController.radialHsbPalette?.contentView.layer.cornerRadius = (self.pickerController.radialHsbPalette?.contentView.frame.height ?? 0)/2
        }
    }
    
    @IBAction func rightBarButtonTapped() {
        if let equipment = self.equipment {
            self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex,device, incomeData) in
                guard let self = self else { return }
                if let equipment = self.equipment, let device = device, let selectedIndex = selectedIndex {
                    let int64 = selectedIndex.map { Int64($0) }
                    if let eqRelays = self.eqRelays, !eqRelays.isEmpty {
                        // edit
                        if let eqDevices = equipment.eqDevice {
                            for item in eqDevices {
                                if let eqDevice = item as? EQDevice {
                                    eqDevice.serial = device.serial
                                    eqDevice.type = device.type
                                }
                            }
                        }
                        eqRelays[0].name = "C-" + String(int64[0]+1)
                        eqRelays[0].digit = int64[0]
                        CoreDataStack.shared.saveContext()
                    } else {
                        CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: int64)
                    }
                    self.fetchAllEQRelayInEquipment()
                    //                    guard let eqRelays = self.eqRelays else { return }
                    //                    guard let eqDevice = eqRelays[0].eqDevice else { return }
                    //                    guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                    self.view.backgroundColor = Constant.Colors.blue
                    self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
                    self.sendBeginData()
                    //                    self.fetchData(device: device)
                }
            }), animated: true, completion: nil)
        }
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            if let eqRelays = self.eqRelays {
                guard !eqRelays.isEmpty else {
                    self.scrollView.alpha = 0.0
                    return
                }
                self.scrollView.alpha = 1.0
                self.rgbTitleLabel.text = (eqRelays[0].name ?? "")
                var serial = "\(eqRelays[0].eqDevice?.serial ?? 0)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                self.descriptionLabel.text = "R\(Int(eqRelays[0].digit)+1)-S/\(serial)"
                self.type = Int(eqRelays[0].digit)
            }
        }
    }
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        guard let eqRelays = self.eqRelays else { return }
        guard let eqDevice = eqRelays[0].eqDevice else { return }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
        var rgb: RGB!
        if eqRelays[0].digit == 0 {
            rgb = RGB(speed: nil, light: UInt8(Int(sender.value)), type: 1, effectType: nil)
        } else {
            rgb = RGB(speed: nil, light: UInt8(Int(sender.value)), type: 2, effectType: nil)
        }
        //        self.view.isUserInteractionEnabled = false
        //        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.6) {
        //            self.view.isUserInteractionEnabled = true
        //        }
        if isSenario {
            self.sendRGB = rgb
        } else {
            self.view.backgroundColor = Constant.Colors.blue
            self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
            NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:4,device: device, typeRequest: .directRequest, items: [:], isDimmer: false, isDaem: false, rgb: rgb) { [weak self] (device, bytes) in
                guard let self = self else { return }
//                guard let device = device, let bytes = bytes else { return }
//                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        }
    }
    
    @IBAction func speedSliderValueChanged(_ sender: UISlider) {
        self.view.backgroundColor = Constant.Colors.blue
        self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
        guard let eqRelays = self.eqRelays else { return }
        guard let eqDevice = eqRelays[0].eqDevice else { return }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
        var rgb: RGB!
        if eqRelays[0].digit == 0 {
            rgb = RGB(speed: UInt8(Int(sender.value)), light: nil, type: 1, effectType: nil)
        } else {
            rgb = RGB(speed: UInt8(Int(sender.value)), light: nil, type: 2, effectType: nil)
        }
        //        self.view.isUserInteractionEnabled = false
        //        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.6) {
        //            self.view.isUserInteractionEnabled = true
        //        }
        if isSenario {
            //
        } else {
            NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:5,device: device, typeRequest: .directRequest, items: [:], isDimmer: false, isDaem: false, rgb: rgb) {[weak self] (device, bytes) in
                guard let self = self else { return }
//                guard let device = device, let bytes = bytes else { return }
//                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        }
    }
    
    @IBAction func rightSideButtonsTapped(_ button: UIButton) {
        let tag = button.tag
        switch tag {
        case 0:
            self.currentSelectedColor = "D"
        case 1:
            self.currentSelectedColor = "W"
        case 2:
            self.currentSelectedColor = "Y"
        case 3:
            self.currentSelectedColor = "P"
        default:
            break
        }
    }
    
    @IBAction func lefttSideButtonsTapped(_ button: UIButton) {
        let tag = button.tag
        switch tag {
        case 0:
            self.currentSelectedColor = "R"
        case 1:
            self.currentSelectedColor = "G"
        case 2:
            self.currentSelectedColor = "B"
        case 3:
            self.currentSelectedColor = "C"
        default:
            break
        }
    }
    
    @IBAction func bottomSideButtonsTapped(_ button: UIButton) {
        var colorName = ""
        self.view.backgroundColor = Constant.Colors.blue
        self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
        guard let eqRelays = self.eqRelays else { return }
        guard let eqDevice = eqRelays[0].eqDevice else { return }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
        var rgb: RGB!
        let type = (eqRelays[0].digit == 0) ? 1:2
        let tag = button.tag
        switch tag {
        case 0:
            colorName = "RB"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 1:
            colorName = "GB"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 2:
            colorName = "RP"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 3:
            colorName = "BC"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 4:
            colorName = "BD"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 5:
            colorName = "RD"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 6:
            colorName = "GD"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 7:
            colorName = "PD"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 8:
            colorName = "YD"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 9:
            colorName = "WD"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 2)
        case 10:
            colorName = "RGB"
            rgb = RGB(speed: nil, light: nil, type: type, effectType: 3)
        case 11:
            var isOn = false
            if isMicrophoneEnable {
                isOn = false
            } else {
                isOn = true
            }
            let effect = isOn ? 4:5
            rgb = RGB(speed: nil, light: nil, type: type, effectType: effect)
            NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:6,device: device, typeRequest: .otherRequest, items: [:], isDimmer: false, isDaem: false, rgb: rgb) { [weak self] (device, bytes) in
                guard let self = self else { return }
//                guard let device = device, let bytes = bytes else { return }
//                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        default:
            break
        }
        if tag != 11 || tag != 10 {
            guard let items = self.convertColorNameToItems(colorNames: colorName) else { return }
            //            self.view.isUserInteractionEnabled = false
            //            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.6) {
            //                self.view.isUserInteractionEnabled = true
            //            }
            NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:7,device: device, typeRequest: .otherRequest, items: items, isDimmer: false, isDaem: false, rgb: rgb) { [weak self] (device, bytes) in
                guard let self = self else { return }
//                guard let device = device, let bytes = bytes else { return }
//                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        }
    }
    
    func convertColorNameToItems(colorNames:String) -> [Int:UInt8]? {
        guard colorNames.count == 2 else {
            return [Int:UInt8]()
        }
        var items = [Int:UInt8]()
        var characters = [Character]()
        for character in colorNames {
            characters.append(character)
        }
        let str1 = String(characters[0])
        let str2 = String(characters[1])
        let color1 = UIColor.fromHex(hexString: defaultColors["\(str1)"]!)
        let color2 = UIColor.fromHex(hexString: defaultColors["\(str2)"]!)
        guard let rgb1 = color1.rgb(), let rgb2 = color2.rgb() else { return nil }
        items[1] = UInt8(rgb1.red)
        items[2] = UInt8(rgb1.green)
        items[3] = UInt8(rgb1.blue)
        items[4] = UInt8(rgb2.red)
        items[5] = UInt8(rgb2.green)
        items[6] = UInt8(rgb2.blue)
        return items
    }
    
    //    override func viewDidAppear(_ animated: Bool) {
    ////        UIColor.fromHex(hexString: defaultColors["B"]!).hsbColor
    ////        self.pickerController.radialHsbPalette!.setSelectedHSBColor(UIColor.fromHex(hexString: defaultColors["B"]!).hsbColor, isInteractive: true)
    //    }
    
    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        if isSenario {
            
        } else {
            self.view.backgroundColor = Constant.Colors.blue
            self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
        }
        updatePallet+=1
    }
    
    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
        //
    }
    
    // --- DEVICE CONNECTION --- //
    private(set) var timer: Timer?
    
    deinit {
        timer?.invalidate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isSenario {
            
        } else {
            self.timer?.invalidate()
            self.timer = nil

        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isSenario {
            
        } else {
            NWSocketConnection.instance.delegate = self
            self.pickerController.radialHsbPalette!.transform = CGAffineTransform.init(scaleX: 1.0, y: -1.0)
            if let eqRelays = self.eqRelays {
                if eqRelays.isEmpty {
                    self.view.backgroundColor = UIColor.systemGroupedBackground
                    self.pickerController.radialHsbPalette?.contentView.layer.borderColor = UIColor.systemBackground.cgColor
                } else {
                    self.view.backgroundColor = Constant.Colors.blue
                    self.pickerController.radialHsbPalette?.contentView.layer.borderColor = Constant.Colors.blue.cgColor
                }
            }
            
            sendBeginData()
            
            self.timer?.invalidate()
            self.timer = nil
            if let equipment = self.equipment, let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] (timer) in
                            guard let self = self else { return }
                            if self.isViewLoaded {
//                                print("isViewLoaded")
                            }
                            NWSocketConnection.mqttSubscriber(device: device, results: nil)
                        })
                    }
                }
            }
        }
    }
    
    func sendBeginData() {
        if let equipment = self.equipment {
            if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        NWSocketConnection.instance.send(tag: 8,device: device, typeRequest: .stateRequest,parameterRequest:.presnetRequest) { [weak self] (bytes,device) in
                            guard let self = self else { return }
//                            guard let device = device, let bytes = bytes else { return }
//                            print("BG,RGB",bytes,device.serial)
//                            self.setDataToCorrectRelay(bytes: bytes,device: device)
                        }
                    }
                }
            }
        }
    }
    
    func setDataToCorrectRelay(bytes: [UInt8],device: Device) {
        guard !bytes.isEmpty else { return }
        var data = bytes
        guard data.count==12 else { return }
        data.removeFirst()
        var color: UIColor!
        var speed: Float!
        var light: Float!
        var isMicEnable: Bool
        guard let eqRelays = self.eqRelays else { return }
        guard let eqDevice = eqRelays[0].eqDevice else { return }
        guard eqDevice.serial == device.serial else { return }
        if eqRelays[0].digit == 0 {
            color = UIColor.init(red: CGFloat(data[0]), green: CGFloat(data[1]), blue: CGFloat(data[2]), alpha: 1.0)
            speed = Float(data[6])
            light = Float(data[8])
            isMicEnable = (data[10] == UInt(1) || data[10] == UInt(3)) ? true:false
        } else {
            color = UIColor.init(red: CGFloat(data[3]), green: CGFloat(data[4]), blue: CGFloat(data[5]), alpha: 1.0)
            speed = Float(data[7])
            light = Float(data[9])
            isMicEnable = (data[10] == UInt(2) || data[10] == UInt(3)) ? true:false
        }
        self.isMicrophoneEnable = isMicEnable
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.speedSlider.setValue(speed, animated: true)
            self.brightnessSlider.setValue(light, animated: true)
            if let rgb = color.rgb() {
                if rgb.red == 0 && rgb.green == 0 && rgb.blue == 0 {
                    let newColor = UIColor.white.hsbColor
                    self.pickerController.radialHsbPalette!.setSelectedHSBColor(newColor, isInteractive: true)
                } else {
                    let hsbColor = color.hsbColor
                    self.pickerController.radialHsbPalette!.setSelectedHSBColor(hsbColor, isInteractive: true)
                }
            }
            let imgName = isMicEnable ? "mic_on":"mic_off"
            self.microphoneButton.setImage(UIImage(named: imgName), for: .normal)
            self.view.backgroundColor = UIColor.groupTableViewBackground
            self.pickerController.radialHsbPalette?.contentView.layer.borderColor = UIColor.systemBackground.cgColor
            //            self.view.isUserInteractionEnabled = true
        }
    }
    
    
}



public extension UIColor {
    
    /// Returns color from its hex string
    ///
    /// - Parameter hexString: the color hex string
    /// - Returns: UIColor
    public static func fromHex(hexString: String) -> UIColor {
        let hex = hexString.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return UIColor.clear
        }
        
        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255)
    }
}
