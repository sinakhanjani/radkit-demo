//
//  ACViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 8/20/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import CircleSlider

class ACViewController: UIViewController, RadkitTableViewCellDelegate, ConfigAdminRolles {
    
    enum FanSpeed {
        case slow,medium,high,auto,off
    }
    enum FanMode {
        case hot,cold,fan,auto,off
    }
    
    func adminChanged() {
        self.admin()
    }
    
    static func create(viewController:UIViewController, equipment: Equipment, completion: ((_ eqRelay: EQRely?,_ data: [UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ACViewController") as! ACViewController
        vc.isSenario = true
        vc.equipment = equipment
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.setViewControllers([vc], animated: true)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
        vc.completion = completion
        viewController.present(navigationController, animated: true, completion: nil)
    }
    
    @IBOutlet var fans: [UIButton]!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var degLabel: UILabel!
    @IBOutlet weak var powerButton: RoundedButton!
    @IBOutlet weak var cricleView: UIView!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var buttonView: RoundedView!
    @IBOutlet weak var tempLabel: UILabel! // °C
    @IBOutlet weak var homeHumLabel: UILabel!
    @IBOutlet weak var homeTempLabel: UILabel!
    @IBOutlet weak var fanView: RoundedView!
    @IBOutlet weak var fanSpeedImageView: UIImageView!
    
    var circleSlider: CircleSlider?
    
    var isSenario: Bool = false
    var equipment: Equipment?
    var eqRelays: [EQRely]?
    ///
    ///
    private var completion: ((_ eqRelay: EQRely?,_ data: [UInt8]?) -> Void)?
    var channelType: Int?
    var fanMode: FanMode = .off {
        willSet {
            switch newValue {
            case .hot:
                buttons[0].setImage(UIImage(named: "mfan"), for: .normal)
                buttons[1].setImage(UIImage(named: "mheat_c"), for: .normal)
                buttons[2].setImage(UIImage(named: "mcool"), for: .normal)
                buttons[3].setImage(UIImage(named: "mauto"), for: .normal)
            case .cold:
                buttons[0].setImage(UIImage(named: "mfan"), for: .normal)
                buttons[1].setImage(UIImage(named: "mheat"), for: .normal)
                buttons[2].setImage(UIImage(named: "mcool_c"), for: .normal)
                buttons[3].setImage(UIImage(named: "mauto"), for: .normal)
            case .fan:
                buttons[0].setImage(UIImage(named: "mfan_c"), for: .normal)
                buttons[1].setImage(UIImage(named: "mheat"), for: .normal)
                buttons[2].setImage(UIImage(named: "mcool"), for: .normal)
                buttons[3].setImage(UIImage(named: "mauto"), for: .normal)
            case .auto:
                buttons[0].setImage(UIImage(named: "mfan"), for: .normal)
                buttons[1].setImage(UIImage(named: "mheat"), for: .normal)
                buttons[2].setImage(UIImage(named: "mcool"), for: .normal)
                buttons[3].setImage(UIImage(named: "mauto_c"), for: .normal)
            case .off:
                buttons[0].setImage(UIImage(named: "mfan"), for: .normal)
                buttons[1].setImage(UIImage(named: "mheat"), for: .normal)
                buttons[2].setImage(UIImage(named: "mcool"), for: .normal)
                buttons[3].setImage(UIImage(named: "mauto"), for: .normal)
            }
        }
    }
    var fanSpeed: FanSpeed = .off {
        willSet {
            switch newValue {
            case .slow:
                fans[0].setImage(UIImage(named: "f1_c"), for: .normal)
                fans[1].setImage(UIImage(named: "f2"), for: .normal)
                fans[2].setImage(UIImage(named: "f3"), for: .normal)
                fans[3].setImage(UIImage(named: "fauto"), for: .normal)
            case .medium:
                fans[0].setImage(UIImage(named: "f1"), for: .normal)
                fans[1].setImage(UIImage(named: "f2_c"), for: .normal)
                fans[2].setImage(UIImage(named: "f3"), for: .normal)
                fans[3].setImage(UIImage(named: "fauto"), for: .normal)
            case .high:
                fans[0].setImage(UIImage(named: "f1"), for: .normal)
                fans[1].setImage(UIImage(named: "f2"), for: .normal)
                fans[2].setImage(UIImage(named: "f3_c"), for: .normal)
                fans[3].setImage(UIImage(named: "fauto"), for: .normal)
            case .auto:
                fans[0].setImage(UIImage(named: "f1"), for: .normal)
                fans[1].setImage(UIImage(named: "f2"), for: .normal)
                fans[2].setImage(UIImage(named: "f3"), for: .normal)
                fans[3].setImage(UIImage(named: "fauto_c"), for: .normal)
            case .off:
                fans[0].setImage(UIImage(named: "f1"), for: .normal)
                fans[1].setImage(UIImage(named: "f2"), for: .normal)
                fans[2].setImage(UIImage(named: "f3"), for: .normal)
                fans[3].setImage(UIImage(named: "fauto"), for: .normal)
            }
        }
    }
    
    var bottomFanSpeed: FanSpeed = .off {
        willSet {
            switch newValue {
            case .slow:
                fanSpeedImageView.image = UIImage(named: "flow")
            case .medium:
                fanSpeedImageView.image = UIImage(named: "fmed")
            case .high:
                fanSpeedImageView.image = UIImage(named: "fhigh")
            case .auto:
                fanSpeedImageView.image = UIImage(named: "fhigh")
            case .off:
                fanSpeedImageView.image = UIImage(named: "foff")
            }
        }
    }
    var isOn = false {
        willSet {
            if newValue {
                self.powerButton.setImage(UIImage(named: "power_red"), for: .normal)
                self.enableAll()
            } else {
                self.powerButton.setImage(UIImage(named: "power_c2"), for: .normal)
                self.disableAll()
            }
        }
    }
    var degTemp: Double?
    // --- DEVICE CONNECTION --- //
    private(set) var timer: Timer?
    
    let hideView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        v.backgroundColor = .systemBackground
        
        return v
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))
            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(backSenarioButtonTapped))
            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen
            
        } else {
            NWSocketConnection.instance.delegate = self
            fetchRequest()
            if let equipment = self.equipment, let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
                            NWSocketConnection.mqttSubscriber(device: device, results: nil)
                        })
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        addCircleSilder()
        //        self.circleSlider?.layer.borderColor = UIColor.darkGray.cgColor
        self.circleSlider?.layer.cornerRadius = self.cricleView.bounds.width/2
        view.addSubview(hideView)
        
        if isSenario {
            self.degTemp = 10.0
            self.circleSlider?.value = 10.0
            self.degLabel.text = "10.0"
        } else {
            backBarButtonAttribute(color: .label, name: "")
        }
        
        if let equipment = self.equipment {
            self.title = equipment.name
        }
        
        fetchAllEQRelayInEquipment()
        self.cricleView.bringSubviewToFront(powerButton)
    }
    
    func disableAll() {
        fans.forEach { button in
            button.isEnabled = false
            button.alpha = 0.8
        }
        buttons.forEach { button in
            button.isEnabled = false
            button.alpha = 0.8
        }
        circleSlider?.isEnabled = false
        circleSlider?.alpha = 0.6
        if isSenario {
            
        } else {
            degLabel.text = "-"
        }
        fans[0].setImage(UIImage(named: "f1"), for: .normal)
        fans[1].setImage(UIImage(named: "f2"), for: .normal)
        fans[2].setImage(UIImage(named: "f3"), for: .normal)
        fans[3].setImage(UIImage(named: "fauto"), for: .normal)
        buttons[0].setImage(UIImage(named: "mfan"), for: .normal)
        buttons[1].setImage(UIImage(named: "mheat"), for: .normal)
        buttons[2].setImage(UIImage(named: "mcool"), for: .normal)
        buttons[3].setImage(UIImage(named: "mauto"), for: .normal)
        fanSpeedImageView.image = UIImage(named: "foff")
    }
    
    func enableAll() {
        fans.forEach { button in
            button.isEnabled = true
            button.alpha = 1
        }
        buttons.forEach { button in
            button.isEnabled = true
            button.alpha = 1
        }
        circleSlider?.isEnabled = true
        circleSlider?.alpha = 1
    }
    
    func addCircleSilder() {
        let options: [CircleSliderOption] = [
            CircleSliderOption.barColor(UIColor.darkGray),
            CircleSliderOption.thumbColor(.white),
            CircleSliderOption.trackingColor(.RADGreen),
            CircleSliderOption.barWidth(20),
            CircleSliderOption.startAngle(-90),
            CircleSliderOption.maxValue(39),
            CircleSliderOption.minValue(10),
        ]
        
        self.circleSlider = CircleSlider(frame: self.cricleView.bounds, options: options)
        self.circleSlider?.addTarget(self, action: #selector(sliderValueChanged(slider:event:)), for: .allTouchEvents)
        self.cricleView.addSubview(self.circleSlider!)
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            guard let eqRelay = self.eqRelays?.first else {
                return
            }
            self.hideView.removeFromSuperview()
            var serial = "\(eqRelay.eqDevice?.serial ?? 0)"
            if serial.count < 6 {
                while serial.count < 6 {
                    serial = "0" + serial
                }
            }
            
            
            self.serialLabel.text = "C\(Int(eqRelay.digit)+1)-S/\(serial)"
            self.channelType = eqRelay.digit == 0 ? 6:7
            // c....
        }
    }
    
    @objc func doneSenarioButtonTapped() {
        if let eqRelays = eqRelays, let eqRelay = eqRelays.first {
            if let data = calculateDirectBytes() {
                self.completion?(eqRelay, data)
            } else {
                self.presentIOSAlertWarning(message: "Please select all entries", completion: {})
            }
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func sliderValueChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began: break
            case .moved:
                if let circleSlider = circleSlider {
                    let roundedValue = round(circleSlider.value * 10) / 10.0
                    if Int((roundedValue*10))%5==0 {
                        self.degLabel.text = String(roundedValue)
                        self.degTemp = Double(roundedValue)
                    }
                }
            case .ended:
                // handle drag ended
                if isSenario {
                    // do nothing
                } else {
                    self.circleSlider?.layer.borderColor = UIColor.RADGreen.cgColor
                    self.circleSlider?.layer.borderWidth = 2
                    self.directReq()
                }
                print("handle drag ended")

            default:
                break
            }
        }
    }
    
    @IBAction func fansButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            self.fanSpeed = .slow
        case 1:
            self.fanSpeed = .medium
        case 2:
            self.fanSpeed = .high
        case 3:
            self.fanSpeed = .auto
        default: break
        }
        if isSenario {
            // do nothing
        } else {
            self.fanView.borderColor = .RADGreen
            self.directReq()
        }
    }
    
    @IBAction func buttonsTappe(_ sender: Any) {
        switch (sender as! UIButton).tag {
        case 0:
            self.fanMode = .fan
        case 1:
            self.fanMode = .hot
        case 2:
            self.fanMode = .cold
        case 3:
            self.fanMode = .auto
        default: break
        }
        if isSenario {
            // do nothing
        } else {
            self.buttonView.borderColor = .RADGreen
            self.directReq()
        }
    }
    
    @IBAction func powerButtonTapped(_ sender: RoundedButton) {
        isOn.toggle()
        if isSenario {
            
        } else {
            powerButton.borderColor = .RADGreen
            directReq()
        }
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
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
                        
                        var serial = "\(device.serial)"
                        if serial.count < 6 {
                            while serial.count < 6 {
                                serial = "0" + serial
                            }
                        }
                        
                        
                        eqRelays[0].name = "C\(int64[0]+1)-S/\(serial)"
                        eqRelays[0].digit = int64[0]
                        
                        CoreDataStack.shared.saveContext()
                    } else {
                        //add
                        CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: int64)
                    }
                    
                    self.fetchAllEQRelayInEquipment()
                    self.fetchRequest()
                }
            }), animated: true, completion: nil)
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

extension ACViewController: NWSocketConnectionDelegate {
    override func viewWillDisappear(_ animated: Bool) {
        if isSenario {
            
        } else {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        if tag == 270 {
            if let bytes = bytes, !bytes.isEmpty {
                calculate(bytes: bytes)
            }
        }
        if tag == 271 {
            if let bytes = bytes, !bytes.isEmpty {
                calculate(bytes: bytes)
            }
        }
        if tag == 1111 && dict?["hearth"] == nil {
            guard let _ = device, let bytes = bytes else { return }
            calculate(bytes: bytes)
        }
    }
    
    func fetchRequest() {
        self.circleSlider?.layer.borderColor = UIColor.RADGreen.cgColor
        if let equipment = self.equipment {
            if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        NWSocketConnection.instance.send(tag:270, device: device, typeRequest: .stateRequest, parameterRequest:.presnetRequest, results: nil)
                    }
                }
            }
        }
    }
    
    func calculate(bytes: [UInt8]) {
        var data = bytes
        guard data.count == 26 else { return }
        data.removeFirst()
        //X1-X25
        updateUI(data: data)
    }
    
    func updateUI(data: [UInt8]) {
        let channel1Parameters = Array(data[0...4])
        let channel2Parameters = Array(data[5...9])
        let humParamteres = Array(data[10...14])
        let temp1Parameters = Array(data[15...16])
        let temp2Parameters = Array(data[17...18])
        let _ = Array(data[19...24]) // end 0000000
        
        DispatchQueue.main.async {
            //set back color
            self.buttonView.borderColor = .darkGray
            self.fanView.borderColor = .darkGray
            self.powerButton.borderColor = .darkGray
            self.circleSlider?.layer.borderColor = nil
            self.circleSlider?.layer.borderWidth = 0
            self.updateChannelUI(channel1: channel1Parameters, channel2: channel2Parameters)
            // hum %
            if humParamteres[0] == UInt8(255) {
                self.homeHumLabel.text = "--"
            } else {
                self.homeHumLabel.text = "\(humParamteres[0]) %"
            }
            // home temp
            if self.channelType == 6 {
                print("YX", temp1Parameters[0...1])
//                if temp1Parameters[1] == UInt8(255) || temp1Parameters[1] == UInt8(128) {
//                    self.homeTempLabel.text = "--"
//                } else {
//                    self.homeTempLabel.text = "\(Double(Int8(bitPattern: temp1Parameters[1]))/10) °C"//
//                }
                let internalTemp = (Double(Int8(bitPattern: UInt8(temp1Parameters[0]))) * 256 + Double(temp1Parameters[1])) / 10
                if internalTemp == -64 {
                    self.homeTempLabel.text = "--"
                } else {
                    self.homeTempLabel.text = "\(internalTemp) °C"//
                }
                // center labl
                self.degLabel.text = "\(Double(Int8(bitPattern: channel1Parameters[3]))/2)"
                self.degTemp = Double(Int8(bitPattern: channel1Parameters[3]))/2
                self.circleSlider?.value = Float(Double(Int8(bitPattern: channel1Parameters[3]))/2)
            } else {
                print("ZX", temp2Parameters[0...1])
//                if temp2Parameters[1] == UInt8(255) || temp2Parameters[1] == UInt(128) {
//                    self.homeTempLabel.text = "--"
//                } else {
//                    self.homeTempLabel.text = "\(Double(Int8(bitPattern: temp2Parameters[1]))/10) °C"
//                }
                let internalTemp = (Double(Int8(bitPattern: UInt8(temp2Parameters[0]))) * 256 + Double(temp2Parameters[1])) / 10
                if internalTemp == -64 {
                    self.homeTempLabel.text = "--"
                } else {
                    self.homeTempLabel.text = "\(internalTemp) °C"//
                }
                //center label
                self.degLabel.text = "\(Double(Int8(bitPattern: channel2Parameters[3]))/2)"
                self.degTemp = Double(Int8(bitPattern: channel2Parameters[3]))/2
                self.circleSlider?.value = Float(Double(Int8(bitPattern: channel2Parameters[3]))/2)
            }
        }
    }
    
    func updateChannelUI(channel1: [UInt8], channel2: [UInt8]) {
        if channel1[0] == UInt(128) || channel1[0] == UInt8(255) {
            self.tempLabel.text = "--"
        } else {
            self.tempLabel.text = "\(Double(Int8(bitPattern: channel1[0]))/2) °C"
        }
        //
        if self.channelType == 6 {
            calculateMode(byte: channel1[2])
            calculateBottomFanSpeed(byte: channel1[1])
        }
        if self.channelType == 7 {
            calculateMode(byte: channel2[2])
            calculateBottomFanSpeed(byte: channel2[1])
        }
        // for both channel use
        sitUI(byte: channel1[1])
    }
    
    func calculateBottomFanSpeed(byte: UInt8) {
        switch byte {
        case UInt8(2):
            self.bottomFanSpeed = .off
            break
        case UInt8(3):
            self.bottomFanSpeed = .slow
            break
        case UInt8(4):
            self.bottomFanSpeed = .medium
            break
        case UInt8(5):
            self.bottomFanSpeed = .high
            break
        default:
            break
        }
    }
    
    func calculateMode(byte: UInt8) {
        let toBit = Data.bits8(fromByte: byte)
        print(toBit)
        //fan speed
        if toBit[0] == .zero && toBit[1] == .zero {
            fanSpeed = .slow
        }
        if toBit[0] == .one && toBit[1] == .zero {
            fanSpeed = .medium
        }
        if toBit[0] == .zero && toBit[1] == .one {
            fanSpeed = .high
        }
        if toBit[0] == .one && toBit[1] == .one {
            fanSpeed = .auto
        }
        // mode
        if toBit[2] == .zero && toBit[3] == .zero {
            fanMode = .hot
        }
        if toBit[2] == .one && toBit[3] == .zero {
            fanMode = .cold
        }
        if toBit[2] == .zero && toBit[3] == .one {
            fanMode = .fan
        }
        if toBit[2] == .one && toBit[3] == .one {
            fanMode = .auto
        }
        // off/on
        if toBit[4] == .zero {
            self.isOn = false
        }
        if toBit[4] == .one {
            self.isOn = true
        }
    }
    
    func sitUI(byte: UInt8) {
        if let equipment = self.equipment {
            switch byte {
            case 0 where equipment.type != 05:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
                break
            case 1 where equipment.type != 05:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
                break
            case 2 where equipment.type != 501 && equipment.type != 503:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
            case 3 where equipment.type != 501 && equipment.type != 503:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
            case 4 where equipment.type != 501 && equipment.type != 503:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
            case 5 where equipment.type != 501 && equipment.type != 503:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
            case 6 where equipment.type != 502:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
            case 7 where equipment.type != 502:
                self.view.addSubview(hideView)
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device", completion: {})
            default:
                break
            }
        }
    }
    
    func calculateDirectBytes() -> [UInt8]? {
        var modeBits: [Data.Bit] = []
        switch fanSpeed {
        case .slow:
            modeBits.append(contentsOf: [.zero,.zero])
        case .medium:
            modeBits.append(contentsOf: [.one,.zero])
        case .high:
            modeBits.append(contentsOf: [.zero,.one])
        case .auto:
            modeBits.append(contentsOf: [.one,.one])
        case .off:
            break
        }
        switch fanMode {
        case .hot:
            modeBits.append(contentsOf: [.zero,.zero])
        case .cold:
            modeBits.append(contentsOf: [.one,.zero])
        case .fan:
            modeBits.append(contentsOf: [.zero,.one])
        case .auto:
            modeBits.append(contentsOf: [.one,.one])
        case .off:
            break
        }
        
        modeBits.append(contentsOf: [isOn ? .one:.zero, .zero, .zero, .zero])
        // [0, 0, 0, 0, 1, 0, 0, 0]
        guard let channelType = channelType, let degTemp = degTemp, fanSpeed != .off && fanMode != .off else {
            return nil
        }
        modeBits = modeBits.reversed()
        
        let modeBytes = Data.bitsToBytes(bits: modeBits)
        
        if let modeByte = modeBytes.first {
            let degTemp = UInt8(Int(degTemp*2))
            let data: [UInt8] = [UInt8(channelType), modeByte, degTemp, UInt8(0)]
            print("SEND DATA \(data)")
            return data
        }
        
        return nil
    }
    
    func directReq() {
        if let data = calculateDirectBytes() {
            if let equipment = self.equipment {
                if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                    eqDevices.forEach { (eqDevice) in
                        if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                            print("SEND DIRECT REQUEST")
                            NWSocketConnection.instance.send(tag: 271, device: device, typeRequest: .directRequest, data: data, results: nil)
                        }
                    }
                }
            }
        }
    }
}
