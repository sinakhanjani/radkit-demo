//
//  EngineViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 8/20/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import CircleSlider

struct EngineModel {
    let outsiDetemp: UInt8
    let enginState: UInt8
    let mode: UInt8
    let tanzim: UInt8
    let enheraf: UInt8
    let enginTemp: UInt8
    let backTemp1: UInt8
    let backTemp2: UInt8
    let backTemp3: UInt8
    let pumpState1: UInt8
    let pumpState2: UInt8
    let pumpState3: UInt8
}

class EngineViewController: UIViewController, ConfigAdminRolles, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        if tag == 280 || tag == 281 {
            if let _ = device, let bytes = bytes {
                calculate(bytes: bytes)
            }
        }
        if tag == 1111 && dict?["hearth"] == nil {
            guard let _ = device, let bytes = bytes else { return }
            calculate(bytes: bytes)
        }
    }
    
    func adminChanged() {
        self.admin()
    }
    
    static func create(viewController:UIViewController, equipment: Equipment, completion: ((_ eqRelay: EQRely?,_ data: [UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EngineViewController") as! EngineViewController
        vc.isSenario = true
        vc.equipment = equipment
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.setViewControllers([vc], animated: true)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
        vc.completion = completion
        viewController.present(navigationController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var sliderView: UIView!
    
    @IBOutlet weak var torchLabel: UILabel!
    @IBOutlet weak var degLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    
    @IBOutlet weak var engineSwitch: UISwitch!
    
    @IBOutlet weak var outsideTempLabel: UILabel!
    @IBOutlet weak var engineTempLabel: UILabel!
    @IBOutlet weak var setTempLabel: UILabel!
    
    // bottom label
    @IBOutlet weak var pump3OnOffLabel: UILabel!
    @IBOutlet weak var pump2OnOffLabel: UILabel!
    @IBOutlet weak var pump1OnOffLabel: UILabel!
    
    @IBOutlet weak var pump3DegLabel: UILabel!
    @IBOutlet weak var pump1DegLabel: UILabel!
    @IBOutlet weak var pump2DegLabel: UILabel!
    
    var circleSlider: CircleSlider?
    
    var isSenario: Bool = false
    var equipment: Equipment?
    var eqRelays: [EQRely]?
    var degTemp: Double?
    private var completion: ((_ eqRelay: EQRely?,_ data: [UInt8]?) -> Void)?

    // --- DEVICE CONNECTION --- //
    private(set) var timer: Timer?
    
    let hideView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        v.backgroundColor = .systemBackground
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addCircleSilder()
        adminAccess()

        view.addSubview(hideView)

        if isSenario {
            self.degLabel.text = "0"
            self.degTemp = 0.0
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                self.circleSlider!.value = Float(0.0)
            }
        } else {
            backBarButtonAttribute(color: .label, name: "")
        }
        
        if let equipment = self.equipment {
            self.title = equipment.name
        }
        
        fetchAllEQRelayInEquipment()
    }
    
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
    
    func addCircleSilder() {
        let options: [CircleSliderOption] = [
            CircleSliderOption.barColor(UIColor.darkGray),
            CircleSliderOption.thumbColor(.white),
            CircleSliderOption.trackingColor(.RADGreen),
            CircleSliderOption.barWidth(20),
            CircleSliderOption.startAngle(-90),
            CircleSliderOption.maxValue(20),
            CircleSliderOption.minValue(-20)
        ]
        
        self.circleSlider = CircleSlider(frame: self.sliderView.bounds, options: options)
        self.circleSlider?.addTarget(self, action: #selector(sliderValueChanged(slider:event:)), for: .allTouchEvents)
        self.sliderView.addSubview(self.circleSlider!)
    }
    
    func fetchRequest() {
        self.circleSlider?.layer.borderColor = UIColor.RADGreen.cgColor
        
        if let equipment = self.equipment {
            if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        NWSocketConnection.instance.send(tag:280, device: device, typeRequest: .stateRequest, parameterRequest:.presnetRequest, results: nil)
                    }
                }
            }
        }
    }
    
    func directReq() {
        if let degTemp = degTemp {
            let data = [UInt8(9),engineSwitch.isOn ? UInt8(1):UInt8(0), UInt8(0), UInt8(bitPattern: Int8(Int(degTemp)))]
            if let equipment = self.equipment {
                if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                    eqDevices.forEach { (eqDevice) in
                        if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                            print("SEND DIRECT REQUEST")
                            NWSocketConnection.instance.send(tag: 281, device: device, typeRequest: .directRequest, data: data, results: nil)
                        }
                    }
                }
            }
        }
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            guard let eqRelays = self.eqRelays, let eqRelay = eqRelays.first else { return }
            self.hideView.removeFromSuperview()
            
            var serial = "\(eqRelay.eqDevice?.serial ?? 0)"
            if serial.count < 6 {
                while serial.count < 6 {
                    serial = "0" + serial
                }
            }
            
            self.serialLabel.text = "C1-S/" + "\(serial)"
        }
    }
    
    func calculate(bytes: [UInt8]) {
        var data = bytes
        guard data.count == 26 else { return }
        data.removeFirst()
        //
        let engineModel = EngineModel(outsiDetemp: data[0], enginState: data[1], mode: data[2], tanzim: data[3], enheraf: data[4], enginTemp: data[5], backTemp1: data[6], backTemp2: data[7], backTemp3: data[8], pumpState1: data[9], pumpState2: data[10], pumpState3: data[11])
        //X1-X25
        updateUI(engineModel: engineModel)
    }
    
    func updateUI(engineModel: EngineModel) {
        DispatchQueue.main.async {
            self.circleSlider?.layer.borderColor = nil
            self.circleSlider?.layer.borderWidth = 0
            
            // [3, 51, 6, 0, 30, 236, 68, 192, 25, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            if engineModel.outsiDetemp == UInt8(128) || engineModel.outsiDetemp == UInt8(255) {
                self.outsideTempLabel.text = "--"
            } else {
                self.outsideTempLabel.text = "\(Double(Int8(bitPattern: engineModel.outsiDetemp))/2)"
            }
            
            if engineModel.enheraf == UInt8(128) || engineModel.enheraf == UInt8(255) {
                self.degLabel.text = "--"
                self.degTemp = Double(engineModel.enheraf)
            } else {
                self.degLabel.text = "\(Int(Int8(bitPattern: engineModel.enheraf)))"
                self.degTemp = Double(Int8(bitPattern: engineModel.enheraf))
                self.circleSlider?.value = Float(Int8(bitPattern: engineModel.enheraf))
            }
            
            if engineModel.enginTemp == UInt8(128) || engineModel.enginTemp == UInt8(255) || engineModel.enginTemp == UInt8(192) {
                self.engineTempLabel.text = "--"
            } else {
                let x = Double(Int8(bitPattern: engineModel.enginTemp))
                if x == -64.0 {
                    self.engineTempLabel.text = "--"
                } else {
                    self.engineTempLabel.text = "\(x)"
                }
                print(Double(Int8(bitPattern: engineModel.enginTemp)))
            }

            self.engineSwitch.isOn = engineModel.mode == UInt8(0) ? false: true
            self.setTempLabel.text = "\(engineModel.tanzim)"
            
            self.pump1DegLabel.text = "\(engineModel.backTemp1 == UInt8(192) ? "--":"\(engineModel.backTemp1)")"
            self.pump2DegLabel.text = "\(engineModel.backTemp2 == UInt8(192) ? "--":"\(engineModel.backTemp2)")"
            self.pump3DegLabel.text = "\(engineModel.backTemp3 == UInt8(192) ? "--":"\(engineModel.backTemp3)")"
            self.pump1OnOffLabel.text = "\(engineModel.pumpState1 == UInt8(1) ? "On":"Off")"
            self.pump2OnOffLabel.text = "\(engineModel.pumpState2 == UInt8(1) ? "On":"Off")"
            self.pump3OnOffLabel.text = "\(engineModel.pumpState3 == UInt8(1) ? "On":"Off")"
            self.torchLabel.text = engineModel.enginState == UInt8(6) ? "Off":"On" //FIX
            self.sitUI(byte: engineModel.enginState)
        }
    }
    
    @objc func sliderValueChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began: break
            case .moved:
                if let circleSlider = circleSlider {
                    self.degLabel.text = String(Int(circleSlider.value))
                    self.degTemp = Double(Int(circleSlider.value))
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
    
    @objc func doneSenarioButtonTapped() {
        if let degTemp = degTemp, let eqRelay = eqRelays?.first {
            let data = [UInt8(9),engineSwitch.isOn ? UInt8(1):UInt8(0), UInt8(0), UInt8(bitPattern: Int8(Int(degTemp)))]
            completion?(eqRelay, data)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func engineSwitchValueChanged(_ sender: Any) {
        if isSenario {
            // do nothing
        } else {
            directReq()
        }
    }
    
    @IBAction func rightBarButtonTapped(_ sender: UIBarButtonItem) {
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
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}
