//
//  ThermostatViewController.swift
//  Master
//
//  Created by Sina khanjani on 10/18/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

struct Thermo {
    let device: Device
    var data0: [UInt8]
    var data1: [UInt8]
    var data2: [UInt8]
    var data3: [UInt8]
    var data4: [UInt8]

}

class ThermostatViewController: UIViewController, RadkitTableViewCellDelegate,ConfigAdminRolles {
    func adminChanged() {
        self.admin()
    }

    // Senario
    private var completion: ((_ eqRelays: EQRely?,_ mode:thermostatMode?,_ tanzimSend:Int?,_ tafazolSend: Int?,_ channel:Int?) -> Void)?
    private var selectedEqRelays: EQRely?
    public var isSenario: Bool = false
    var modeSend:thermostatMode = .off {
        willSet {
            print("MODESEND:\(newValue)")
        }
    }
    var tanzimSend:Int = 25
    var tafazolSend:Int = 2
    
    var itemTags:[Int] = []
    var thermos = [Thermo]()
        
    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ mode:thermostatMode?,_ tanzimSend:Int?,_ tafazolSend: Int?,_ channel:Int?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ThermostatViewController") as! ThermostatViewController
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
        if let selectedEqRelay = self.selectedEqRelays {
            self.completion?(selectedEqRelay,modeSend,tanzimSend,tafazolSend,Int(selectedEqRelay.digit)+1)
        } else {
            completion?(nil,nil,nil,nil,nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var equipment: Equipment?
    var eqRelays: [EQRely]?
//    var datas:[[UInt8]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
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
            backBarButtonAttribute(color: .white, name: "")
        }
        if let equipment = self.equipment {
            self.title = equipment.name
        }
        
        fetchAllEQRelayInEquipment()
    }
    
    @IBAction func rightBarButtonTapped() {
        if let equipment = self.equipment {
            self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex,device, incomeData) in
                guard let self = self else { return }
                if let equipment = self.equipment, let device = device, let selectedIndex = selectedIndex {
                    let int64 = selectedIndex.map { Int64($0) }
                    CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: int64)
                    self.fetchAllEQRelayInEquipment()
                    self.sendBeginData()
                }
            }), animated: true, completion: nil)
        }
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            guard let eqRelays = self.eqRelays else { return }
            if isSenario {
                self.itemTags = [Int](repeating: 3, count: eqRelays.count)
            }
//            self.datas = [[UInt8]](repeating: [], count: eqRelays.count)
            self.tableView.reloadData()
        }
    }
    
    func sendDirectRequest(device:Device,channel:Int,mode: thermostatMode,temp: Int,residuum: Int) {
        let data = [UInt8(channel),UInt8(mode.rawValue),UInt8(temp),UInt8(residuum)]
        NWSocketConnection.instance.send(tag:1, device: device, typeRequest: .directRequest, data: data, results: nil)
    }
    
    //// Protocol
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadkitTableViewCell) {
        if isSenario {
            
        } else {
            guard let eqRelays = self.eqRelays else { return }
            if let indexPath = tableView.indexPath(for: cell) {
                let _ = eqRelays[indexPath.item]
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
                        if let items = self.eqRelays {
                            self.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                                guard let self = self else { return }
                                CoreDataStack.shared.updateEQRelayName(eqRelay: items[indexPath.item], name: name)
                                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            }
                        }
                    }
                    let remove = UIAlertAction.init(title: "Delete Output", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays {
                            self.presentIOSAlertWarningWithTwoButton(message:"Do you want to delete this output?", buttonOneTitle:"Yes", buttonTwoTitle:"No", handlerButtonOne: { [weak self] in
                                guard let self = self else { return }
                                CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: items[indexPath.item])
                                self.fetchAllEQRelayInEquipment()
                                self.sendBeginData()
                            }) {
                                //
                            }
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
    
    func button1Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        // damaye tanzim
        if let indexPath = tableView.indexPath(for: cell) {
            PickerViewController.create(viewController: self, title:"Set Temperature", isSetting: false) { [weak self] (result) in
                guard let self = self else { return }
                if let result = result {
                    guard let eqRelays = self.eqRelays else { return }
                    if self.isSenario {
                        //modeSend ok
                        self.tanzimSend = result
                        self.selectedEqRelays = self.eqRelays![indexPath.item]
                        self.tableView.reloadData()
                    } else {
                        guard let eqDevice = eqRelays[indexPath.item].eqDevice else { return }
                        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                        guard let cell = self.tableView.cellForRow(at: indexPath) as? RadkitTableViewCell else { return }
                        guard let thermo = self.thermos.first(where: { th in
                            th.device.serial == eqDevice.serial
                        }) else { return }
                        let digit = Int(self.eqRelays![indexPath.item].digit)
                        var dataItems = [UInt8]()
                        switch digit {
                        case 0:
                            dataItems = thermo.data0
                        case 1:
                            dataItems = thermo.data1
                        case 2:
                            dataItems = thermo.data2
                        case 3:
                            dataItems = thermo.data3
                        case 4:
                            dataItems = thermo.data4
                        default: break
                        }
                        
                        cell.roundedView1.borderColor = Constant.Colors.blue
                        var mode: thermostatMode = thermostatMode.off
                        switch Int(dataItems[2]) {
                        case 0:
                            mode = .warm
                        case 1:
                            mode = .cold
                        case 2:
                            mode = .off
                        case 3:
                            mode = .on
                        default:
                            break
                        }
                        self.sendDirectRequest(device: device, channel: Int(eqRelays[indexPath.item].digit)+1, mode: mode, temp: result, residuum: Int(dataItems[4]))
                    }
                }
            }
        }
    }
    
    func button2Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        // damaye tafazol
        if let indexPath = tableView.indexPath(for: cell) {
            PickerViewController.create(viewController: self, title: "Temperature Difference", isSetting: true) { [weak self] (result) in
                guard let self = self else { return }
                if let result = result {
                    guard let eqRelays = self.eqRelays else { return }
                    if self.isSenario {
                        //mode send ok
                        self.tafazolSend = result
                        self.selectedEqRelays = self.eqRelays![indexPath.item]
                        self.tableView.reloadData()
                    } else {
                        guard let eqDevice = eqRelays[indexPath.item].eqDevice else { return }
                        guard let thermo = self.thermos.first(where: { th in
                            th.device.serial == eqDevice.serial
                        }) else { return }
                        let digit = Int(self.eqRelays![indexPath.item].digit)
                        var dataItems = [UInt8]()
                        switch digit {
                        case 0:
                            dataItems = thermo.data0
                        case 1:
                            dataItems = thermo.data1
                        case 2:
                            dataItems = thermo.data2
                        case 3:
                            dataItems = thermo.data3
                        case 4:
                            dataItems = thermo.data4
                        default: break
                        }
                        
                        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                        guard let cell = self.tableView.cellForRow(at: indexPath) as? RadkitTableViewCell else { return }
                        cell.roundedView1.borderColor = Constant.Colors.blue
                        var mode: thermostatMode = thermostatMode.off
                        switch Int(dataItems[2]) {
                        case 0:
                            mode = .warm
                        case 1:
                            mode = .cold
                        case 2:
                            mode = .off
                        case 3:
                            mode = .on
                        default:
                            break
                        }
                        self.sendDirectRequest(device: device, channel: Int(eqRelays[indexPath.item].digit)+1, mode: mode, temp: Int(dataItems[3]), residuum: result)
                    }
                }
            }
        }
    }
    
    func button3Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            guard let eqRelays = self.eqRelays else { return }
            if self.isSenario {
                let tag = self.itemTags[indexPath.item]
                print("index",indexPath.item, " tag:\(tag)")
                var mode: thermostatMode = .off
                switch tag {
                case 0:
                    mode = .warm
                    sender.tag = 1
                    self.itemTags[indexPath.item] = 1
                case 1:
                    mode = .cold
                    sender.tag = 2
                    self.itemTags[indexPath.item] = 2
                case 2:
                    mode = .off
                    sender.tag = 3
                    self.itemTags[indexPath.item] = 3
                case 3:
                    mode = .on
                    sender.tag = 0
                    self.itemTags[indexPath.item] = 0
                default:
                    break
                }
                self.selectedEqRelays = self.eqRelays![indexPath.item]
                self.modeSend = mode
                self.tableView.reloadData()
            } else {
                guard let eqDevice = eqRelays[indexPath.item].eqDevice else { return }
                guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                guard let cell = self.tableView.cellForRow(at: indexPath) as? RadkitTableViewCell else { return }
                guard let thermo = self.thermos.first(where: { th in
                    th.device.serial == eqDevice.serial
                }) else { return }
                let digit = Int(self.eqRelays![indexPath.item].digit)
                var dataItems = [UInt8]()
                switch digit {
                case 0:
                    dataItems = thermo.data0
                case 1:
                    dataItems = thermo.data1
                case 2:
                    dataItems = thermo.data2
                case 3:
                    dataItems = thermo.data3
                case 4:
                    dataItems = thermo.data4
                default: break
                }
                
                cell.roundedView1.borderColor = Constant.Colors.blue
                var mode: thermostatMode = thermostatMode.off
                switch Int(dataItems[2]) {
                case 0:
                    mode = .cold
                case 1:
                    mode = .off
                case 2:
                    mode = .on
                case 3:
                    mode = .warm
                default:
                    break
                }
                print("mode: \(mode) \(Int(dataItems[2]))")
              self.sendDirectRequest(device: device, channel: Int(eqRelays[indexPath.item].digit)+1, mode: mode, temp: Int(dataItems[3]), residuum: Int(dataItems[4]))
            }
        }
    }
    
    // --- DEVICE CONNECTION --- //
    private(set) var timer: Timer?
    
    deinit {
        timer?.invalidate()
        timer = nil
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
            //
        } else {
            NWSocketConnection.instance.delegate = self
            sendBeginData()
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
    
    func sendBeginData() {
        if let equipment = self.equipment {
            if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                self.thermos = []
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        NWSocketConnection.instance.send(tag: 2, device: device, typeRequest: .stateRequest,parameterRequest:.presnetRequest, results: nil)
                    }
                }
            }
        }
    }
    
    func setDataToCorrectRelay(bytes: [UInt8], device: Device) {
        guard !bytes.isEmpty else { return }
        var data = bytes
        guard data.count == 26 else { return }
        data.removeFirst()
        
        let rel1 = Array(data[0...4])
        let rel2 = Array(data[5...9])
        let rel3 = Array(data[10...14])
        let rel4 = Array(data[15...19])
        let rel5 = Array(data[20...24])
        let relays = [rel1,rel2,rel3,rel4,rel5]
        
        if let index = self.thermos.firstIndex(where: { th in
            th.device.serial == device.serial
        }) {
            self.thermos[index].data0 = relays[0]
            self.thermos[index].data1 = relays[1]
            self.thermos[index].data2 = relays[2]
            self.thermos[index].data3 = relays[3]
            self.thermos[index].data4 = relays[4]
        } else {
            let th = Thermo(device: device, data0: rel1, data1: rel2, data2: rel3, data3: rel4, data4: rel5)
            self.thermos.append(th)
        }
        
        // part alert
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sitUI(byte: rel1[1], device: device)
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
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
                break
            case 1 where equipment.type != 05:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
                break
            case 2 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
            case 3 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
            case 4 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
            case 5 where equipment.type != 501 && equipment.type != 503:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
            case 6 where equipment.type != 502:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
            case 7 where equipment.type != 502:
                self.presentIOSAlertWarning(message: "Check the working mode settings of the device S/\(serial)", completion: {})
            default:
                break
            }
        }
    }
}

extension ThermostatViewController :UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eqRelays?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
        cell.delegate = self
        //label1: 26.0c
        //label2: T2
        //label3: serial device
        //button1: damaye tanzim
        //button2: tafazol
        //button3: khorshid
        //view1: line red
        if isSenario {
            if let items = self.eqRelays {
            let item = items[indexPath.item]
                cell.label_2.text = (item.name ?? "")
                var serial = "\(item.eqDevice?.serial ?? 0)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                cell.label_3.text = "R\(Int(item.digit)+1)-S/\(serial)"
//                let tag = cell.button3.tag
                let tag = self.itemTags[indexPath.item]
                switch tag {
                case 0:
                    cell.button3.setImage(UIImage(named: "ON"), for: .normal)
                case 1:
                    cell.button3.setImage(UIImage(named: "sun"), for: .normal)
                case 2:
                    cell.button3.setImage(UIImage(named: "ice"), for: .normal)
                case 3:
                    cell.button3.setImage(UIImage(named: "power_red"), for: .normal)
                default:
                    cell.button3.setImage(UIImage(named: "power_red"), for: .normal)
                }
            }
            if let selectedEqRelay = self.selectedEqRelays {
                if selectedEqRelay.objectID == self.eqRelays![indexPath.item].objectID {
                    cell.roundedView1.borderColor = Constant.Colors.blue
                    cell.button1.setTitle("\(self.tanzimSend)", for: .normal)
                    cell.button2.setTitle("\(self.tafazolSend)", for: .normal)
                } else {
                    cell.button1.setTitle("\(25)", for: .normal)
                    cell.button2.setTitle("\(2)", for: .normal)
                    cell.roundedView1.borderColor = .separator
                }
            } else {
                cell.button1.setTitle("\(25)", for: .normal)
                cell.button2.setTitle("\(2)", for: .normal)
                cell.roundedView1.borderColor = .separator
            }
        } else {
            cell.roundedView1.borderColor = .separator
            if let items = self.eqRelays {
            let item = items[indexPath.item]
                cell.label_2.text = (item.name ?? "")
                var serial = "\(item.eqDevice?.serial ?? 0)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                cell.label_3.text = "R\(Int(item.digit)+1)-S/\(serial)"
            }
            if let eqRelays = self.eqRelays {
                let eqRelay = eqRelays[indexPath.item]
                let digit = Int(eqRelay.digit)
                
                if let thermo = self.thermos.first(where: { th in
                    th.device.serial == eqRelay.eqDevice?.serial
                }) {
                    switch digit {
                    case 0:
                        updateItem(data: thermo.data0)
                    case 1:
                        updateItem(data: thermo.data1)
                    case 2:
                        updateItem(data: thermo.data2)
                    case 3:
                        updateItem(data: thermo.data3)
                    case 4:
                        updateItem(data: thermo.data4)
                    default: break
                    }
                }
            }
            
            func updateItem(data: [UInt8]) {
                if Int8(bitPattern: data[0]) == -128 {
                    cell.label_1.text = "--"
                } else {
                    cell.label_1.text = "\(Double(Int8(bitPattern: data[0]))/2)"
                }

                cell.button1.setTitle("\(data[3])", for: .normal)
                cell.button2.setTitle("\(data[4])", for: .normal)
                switch Int(data[2]) {
                case 0:
                    cell.button3.setImage(UIImage(named: "sun"), for: .normal)
                case 1:
                    cell.button3.setImage(UIImage(named: "ice"), for: .normal)
                case 2:
                    cell.button3.setImage(UIImage(named: "power_red"), for: .normal)
                case 3:
                    cell.button3.setImage(UIImage(named: "ON"), for: .normal)
                default:
                    cell.button3.setImage(UIImage(named: "power_red"), for: .normal)
                }
                cell.view1.backgroundColor = (data[1] == UInt8(0) ? UIColor.red:UIColor.green)
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSenario {
            guard let _ = eqRelays else { return }
            self.tanzimSend = 25
            self.tafazolSend = 2
            self.modeSend = .off
            self.selectedEqRelays = self.eqRelays![indexPath.item]
            self.tableView.reloadData()
        } else {
            //
        }
    }
}

extension ThermostatViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("THERMO - ", "Tag: \(tag)",bytes ?? [], device?.serial ?? 0)
        
        if tag == 1 {
            if let device = device, let bytes = bytes {
                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        }
        if tag == 2 {
            if let device = device, let bytes = bytes {
                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        }
        if tag == 1111 && dict?["hearth"] == nil {
            if let device = device, let bytes = bytes {
                self.setDataToCorrectRelay(bytes: bytes, device: device)
            }
        }
    }
}
