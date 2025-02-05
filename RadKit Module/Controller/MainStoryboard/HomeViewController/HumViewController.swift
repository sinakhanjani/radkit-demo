//
//  HumViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 8/20/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit


struct Hum {
    enum HumMode: Int {
        case hum = 0
        case dry = 1
        case off = 2
        case on = 3
    }
    let isOn: Bool
    let hum: UInt8?
    let mode: HumMode
    let tanzimHum: UInt8?
    let tafazolHum: UInt8?
    let eqRelay: EQRely
    let device: Device
    
    init(eqRelay: EQRely, device: Device) {
        self.isOn = false
        self.hum = nil
        self.mode = .off
        self.tanzimHum = nil
        self.tafazolHum = nil
        self.device = device
        self.eqRelay = eqRelay
    }
    
    init(isOn: Bool, hum: UInt8?, mode: HumMode, tanzimHum: UInt8?, tafazolHum: UInt8?, eqRelay: EQRely, device: Device) {
        self.isOn = isOn
        self.hum = hum
        self.mode = mode
        self.tanzimHum = tanzimHum
        self.tafazolHum = tafazolHum
        self.eqRelay = eqRelay
        self.device = device
    }
}

class HumViewController: UIViewController, ConfigAdminRolles, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        if tag == 291 {
            if let device = device, let bytes = bytes {
                if let eqRelay = self.hums.first(where: { hum in
                    hum.device.serial == device.serial
                })?.eqRelay {
                    calculate(bytes: bytes, eqRelay: eqRelay, device: device)
                }
            }
        }
        if tag == 290 {
            if let device = device, let bytes = bytes {
                if let eqRelay = self.hums.first(where: { hum in
                    hum.device.serial == device.serial
                })?.eqRelay {
                    calculate(bytes: bytes, eqRelay: eqRelay, device: device)
                }
            }
        }
        if tag == 1111 && dict?["hearth"] == nil {
            guard let device = device, let bytes = bytes else { return }
            if let eqRelay = self.hums.first(where: { hum in
                hum.device.serial == device.serial
            })?.eqRelay {
                calculate(bytes: bytes, eqRelay: eqRelay, device: device)
            }
        }
    }
    
    func adminChanged() {
        self.admin()
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var isSenario: Bool = false
    var equipment: Equipment?
    var hums: [Hum] = []
    
    var selectedHum: Hum?
    
    // --- DEVICE CONNECTION --- //
    private(set) var timer: Timer?
    private var completion: ((_ eqRelays: EQRely?,_ sendData: [UInt8]?) -> Void)?

    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ sendData: [UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HumViewController") as! HumViewController
        vc.isSenario = true
        vc.equipment = equipment
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.setViewControllers([vc], animated: true)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
        vc.completion = completion
        viewController.present(navigationController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()

        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))
            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(backSenarioButtonTapped))
//            leftBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen
        } else {
            backBarButtonAttribute(color: .label, name: "")
        }
        
        if let equipment = self.equipment {
            self.title = equipment.name
        }
        fetchAllEQRelayInEquipment()
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
            fetchRequest()
            self.timer?.invalidate()
            self.timer = nil
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
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            let eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)

            self.hums = []
            
            eqRelays.forEach({ eqRelay in
                if let eqDevice = eqRelay.eqDevice {
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        let hum = Hum.init(eqRelay: eqRelay, device: device)
                        if let index = hums.firstIndex(where: { i in
                            return i.device.serial == hum.device.serial
                        }) {
                            self.hums[index] = hum
                        } else {
                            self.hums.append(hum)
                        }
                    }
                }
            })
            
            self.tableView.reloadData()
        }
    }
    
    func fetchRequest() {
        for (index,hum) in hums.enumerated() {
            NWSocketConnection.instance.send(dict: ["index": index], tag:290, device: hum.device, typeRequest: .stateRequest, parameterRequest:.presnetRequest, results: nil)
        }
    }
    
    func sendRequest(hum: Hum) {
        let device = hum.device
        let data = toData(hum: hum)
        NWSocketConnection.instance.send(tag:291, device: device, typeRequest: .directRequest,data: data, results: nil)
    }
    
    func toData(hum: Hum) -> [UInt8]? {
        if let tanzim = hum.tanzimHum, let tafazol = hum.tafazolHum {
            let data = [UInt8(8),UInt8(hum.mode.rawValue),UInt8(tanzim),UInt8(tafazol)]
            return data
        } else {
            self.presentIOSAlertWarning(message: "Please select all input", completion: {})
        }

        return nil
    }
    
    func calculate(bytes: [UInt8], eqRelay: EQRely, device: Device) {
        var data = bytes
        guard data.count == 26 else { return }
        data.removeFirst()
        //X1-X25
        updateUI(data: data, eqRelay: eqRelay, device: device)
    }
    
    func updateUI(data: [UInt8], eqRelay: EQRely, device: Device) {
        let channel1Parameters = Array(data[0...4])
//        let channel2Parameters = Array(data[5...9])
        let humParamteres = Array(data[10...14])
//        let temp1Parameters = Array(data[15...16])
//        let temp2Parameters = Array(data[17...18])
        let _ = Array(data[19...24]) // end 0000000
        
        var humMode: Hum.HumMode = .off
        
        switch humParamteres[2] {
        case 0: humMode = .hum
        case 1: humMode = .dry
        case 2: humMode = .off
        case 3: humMode = .on
        default: break
        }
        
        let hum = Hum.init(isOn: humParamteres[1] == 0 ? false:true, hum: humParamteres[0], mode: humMode, tanzimHum: humParamteres[3], tafazolHum: humParamteres[4], eqRelay: eqRelay, device: device)
        if let index = hums.firstIndex(where: { i in
            return i.device.serial == hum.device.serial
        }) {
            self.hums[index] = hum
        } else {
            self.hums.append(hum)
        }
        
        DispatchQueue.main.async {
            self.sitUI(byte: channel1Parameters[1], device: device)
            self.tableView.reloadData()
        }
    }
    
    func sitUI(byte: UInt8, device: Device) {
        var serial = "\(device.serial)"
        if serial.count < 6 {
            while serial.count < 6 {
                serial = "0" + serial
            }
        }
        
        
        if let equipment = self.equipment {
            switch byte {
            case 0 where equipment.type != 05:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
                break
            case 1 where equipment.type != 05:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
                break
            case 2 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
            case 3 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
            case 4 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
            case 5 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
            case 6 where equipment.type != 502:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
            case 7 where equipment.type != 502:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device R1-S\(serial)", completion: {})
            default:
                break
            }
        }
    }
    
    @objc func doneSenarioButtonTapped() {
        if let selectedHum = selectedHum {
            let data = toData(hum: selectedHum)
            completion?(selectedHum.eqRelay, data)
        }
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        if let equipment = self.equipment {
            self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex, device, incomeData) in
                guard let self = self else { return }
                if let equipment = self.equipment, let device = device, let _ = selectedIndex {
                    let eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
                    if let eqRelay = eqRelays.first(where: { item in
                        item.eqDevice?.serial == device.serial
                    }) {
                        // remove old one first if available 
                        CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: eqRelay)
                    }
                    // add new one
                    CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: [Int64(self.hums.count-1)])
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

extension HumViewController: UITableViewDelegate, UITableViewDataSource, RadkitTableViewCellDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
        
        cell.delegate = self
        
        let hum = hums[indexPath.item]

        if isSenario {
            if let selectedHum = self.selectedHum {
                if hum.device.serial == selectedHum.device.serial {
                    cell.roundedView1.borderColor = .RADGreen
                } else {
                    cell.roundedView1.borderColor = .separator
                }
            } else {
                cell.roundedView1.borderColor = .separator
            }
        }
        
        let mode = hum.mode
        // mode
        switch mode {
        case .hum:
            cell.button3.setImage(UIImage(named: "humidi"), for: .normal)
        case .dry:
            cell.button3.setImage(UIImage(named: "dryer"), for: .normal)
        case .off:
            cell.button3.setImage(UIImage(named: "power_red"), for: .normal)
        case .on:
            cell.button3.setImage(UIImage(named: "ON"), for: .normal)
        }
        
        if let tafazol = hum.tafazolHum {
            cell.button2.setTitle("\(tafazol)", for: .normal)
        }
        if let tanzim = hum.tanzimHum {
            cell.button1.setTitle("\(tanzim)", for: .normal)
        }
        
        cell.roundedView1.borderColor = .separator
        
        if let humPercent = hum.hum {
            if (humPercent) == UInt(255) {
                cell.label_1.text = "--"
            } else {
                cell.label_1.text = "\(humPercent)"
            }
        }
        
        if let name = hum.eqRelay.name {
            if name.hasPrefix("T-") {
                cell.label_2.text = "H-\(indexPath.item+1)"
            } else {
                cell.label_2.text = name
            }
        } else {
            cell.label_2.text = "H-\(indexPath.item+1)"
        }
        
        cell.label_3.text = "R1-S/\(hum.device.serial)"
        
        cell.view1.backgroundColor = (!hum.isOn ? UIColor.red:UIColor.green)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSenario {
            let hum = self.hums[indexPath.item]
            self.selectedHum = hum
            self.tableView.reloadData()
        }
    }
    
    func button1Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let hum = self.hums[indexPath.item]
            PickerViewController.create(viewController: self, title: "Set Humidity", isSetting: true, isHum: true) { [weak self] (result) in
                guard let self = self else { return }
                if let result = result {
                    let sendHum = Hum.init(isOn: hum.isOn, hum: hum.hum, mode: hum.mode, tanzimHum: UInt8(result), tafazolHum: hum.tafazolHum, eqRelay: hum.eqRelay, device: hum.device)

                    if self.isSenario {
                        self.selectedHum = sendHum
                        self.hums[indexPath.item] = sendHum
                        self.tableView.reloadData()
                    } else {
                        self.sendRequest(hum: sendHum)
                    }
                }
            }
        }
    }
    
    func button2Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let hum = self.hums[indexPath.item]
            PickerViewController.create(viewController: self, title: "Humidity Difference", isSetting: false, isHum: true) { [weak self] (result) in
                guard let self = self else { return }
                if let result = result {
                    let sendHum = Hum.init(isOn: hum.isOn, hum: hum.hum, mode: hum.mode, tanzimHum: hum.tanzimHum, tafazolHum: UInt8(result), eqRelay: hum.eqRelay, device: hum.device)

                    if self.isSenario {
                        self.selectedHum = sendHum
                        self.hums[indexPath.item] = sendHum
                        self.tableView.reloadData()
                    } else {
                        self.sendRequest(hum: sendHum)
                    }
                }
            }
        }
    }
    
    func button3Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let hum = self.hums[indexPath.item]
            var mode: Hum.HumMode = .off
            
            switch hum.mode {
            case .hum:
                cell.button3.setImage(UIImage(named: "dryer"), for: .normal)
                mode = .dry
            case .dry:
                cell.button3.setImage(UIImage(named: "power_red"), for: .normal)
                mode = Hum.HumMode.off
            case .off:
                cell.button3.setImage(UIImage(named: "ON"), for: .normal)
                mode = .on
            case .on:
                cell.button3.setImage(UIImage(named: "humidi"), for: .normal)
                mode = .hum
            }
            
            let sendHum = Hum.init(isOn: hum.isOn, hum: hum.hum, mode: mode, tanzimHum: hum.tanzimHum, tafazolHum: hum.tafazolHum, eqRelay: hum.eqRelay, device: hum.device)

            if isSenario {
                self.selectedHum = hum
                self.hums[indexPath.item] = sendHum
                self.tableView.reloadData()
            } else {
                cell.roundedView1.borderColor = .RADGreen
                self.sendRequest(hum: sendHum)
            }
        }
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadkitTableViewCell) {
        if isSenario {
            // do nothing
        } else {
            if let indexPath = tableView.indexPath(for: cell) {
                let _ = hums[indexPath.item]
                switch sender.state {
                case .possible:
                    break
                case .began:
                    let message = "Do you want to delete this output?"
                    let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
                    let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                        //
                    }
                    let changeName = UIAlertAction.init(title: "Rename", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        self.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                            guard let self = self else { return }
                            CoreDataStack.shared.updateEQRelayName(eqRelay: self.hums[indexPath.item].eqRelay, name: name)
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                    let remove = UIAlertAction.init(title: "Delete Output", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        self.presentIOSAlertWarningWithTwoButton(message:"Do you want to delete this output?", buttonOneTitle:"Yes", buttonTwoTitle:"No", handlerButtonOne: { [weak self] in
                            guard let self = self else { return }
                            CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: self.hums[indexPath.item].eqRelay)
                            self.fetchAllEQRelayInEquipment()
                            self.fetchRequest()
                        }) {
                            //
                        }
                    }
                    cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
                    alertController.addAction(cancelAction)
                    remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(remove)
                    changeName.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(changeName)
                    if Password.shared.adminMode {
                        self.present(alertController, animated: true, completion: nil)
                    }
                case .changed:
                    break
                case .ended:
                    break
                case .cancelled:
                    break
                case .failed:
                    break
                default:
                    break
                }
            }
        }
    }
}

// dryer - khosh image name
// humidi - rotobatsaz image name
