//
//  SenarioMainViewController.swift
//  Master
//
//  Created by Sina khanjani on 11/15/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit
import ProgressHUD

class SenarioMainViewController: UIViewController,ConfigAdminRolles, NWSocketConnectionDelegate {
    var allDevicesScenarioItems = [String]()
    var count = 0
    
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("SenarioMain - TAG \(tag), \(device?.serial ?? 0) \(bytes ?? [])")
        
        if let device = device, let bytes = bytes, let fByte = bytes.first, bytes.count == 2 {
            if fByte == UInt8(8) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    var serial = "\(device.serial)"
                    if serial.count < 6 {
                        while serial.count < 6 {
                            serial = "0" + serial
                        }
                    }
                    
                    if bytes[0] == UInt8(8) && bytes[1] == UInt8(0) {
                        // this is for only run bus scenario
                        self.allDevicesScenarioItems.append("\(serial)")
                        NotificationCenter.default.post(name: Notification.Name("ReceievdSenarioSuccess"), object: nil)
                        if self.count == self.allDevicesScenarioItems.count {
                            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.addedScenarioAllDeviceMsg), object: nil)
                            self.addedScenarioAllDeviceMsg()
                        }
                    } else {
                        if let vc = SenarioConnection.warningVC {
                            vc.dismiss(animated: true) { [weak self] in
                                if let self = self {
                                    let msg = "Assigned to external scenario channel \(bytes[1]) in device \(serial)"
                                    DispatchQueue.main.async { [weak self] in
                                        self?.presentIOSAlertWarning(message: msg) {
                                            SenarioConnection.warningVC = nil
                                        }
                                    }
                                }
                            }
                        } else {
                            // this is for all set assign to scenario
                            let msg = "Assigned to external scenario channel \(bytes[1]) in device \(serial)"
                            DispatchQueue.main.async { [weak self] in
                                self?.presentIOSAlertWarning(message: msg) {}
                            }
                        }
                    }
                }
                
                return
            }
            
            if fByte == UInt8(13) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let type = DeviceType.init(rawValue: Int(device.type))!
                    var serial = "\(device.serial)"
                    
                    if serial.count < 6 {
                        while serial.count < 6 {
                            serial = "0" + serial
                        }
                    }
                    
                    switch type {
                    case .tv,.remotes,.wifi:
                        DispatchQueue.main.async { [weak self] in
                            SenarioConnection.warningVC?.dismiss(animated: true, completion: {
                                self?.presentIOSAlertWarning(message: "Assigned to external channel \(Int (bytes[1])) device \(serial)") {
                                    SenarioConnection.warningVC = nil
                                }
                            })
                        }
                    default:
                        let msg = "Bus scenario channel \(bytes[1])" + " " + "assigned to" + " " + "device \(serial)" + "" + "."
                        DispatchQueue.main.async { [weak self] in
                            self?.presentIOSAlertWarning(message: msg) {}
                        }
                    }
                }
                
                return
            }
        }
        
        if (tag == 49) || (tag == 1111 && dict?["hearth"] == nil) {
            guard let bytes = bytes, let device = device else { return }
            guard let fByte = bytes.first, fByte == UInt8(6) else { return }
            var weeklys1 = [Weekly]()
            let _ = bytes[0] // header
            let count = Int(bytes[1]) // count
            var usedBytes = bytes
            usedBytes.removeFirst()
            usedBytes.removeFirst()
            for _ in 1..<count+1 {
                if usedBytes.count % 34 == 0 {
                    //add to weekly
                    //name:
                    guard usedBytes.count > 30 else { return } // new.
                    var inputBytes: [UInt8] = Array(usedBytes[4...33])
                    let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                    let dataStr = Data.init(referencing: nsdata)
                    let weekly = Weekly(hour: Int(usedBytes[0]), time: Int(usedBytes[1]), days: self.dayByteToBit(byte: usedBytes[2]), code: Int(usedBytes[3]), name: String(data: dataStr, encoding: .utf8) ?? "", device: device)
                    weeklys1.append(weekly)
                    usedBytes.removeSubrange(0..<34)
                }
            }
            // weeklys1
            self.weeklys.append(contentsOf: weeklys1)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        }
        
        if (tag == 47) {
            self.fetchAllWeeklys()
        }
    }
    
    func adminChanged() {
        admin()
    }

    @IBOutlet weak var warningTitleLabel: UILabel!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    private var senarioType:SenarioType = .senario {
        willSet {
            if newValue == .senario {
                self.senarioType = .senario
                self.collectionView.alpha = 1.0
                self.tableView.alpha = 0.0
            } else {
                self.senarioType = .weekly
                self.collectionView.alpha = 0.0
                self.tableView.alpha = 1.0
                fetchAllWeeklys()
            }
        }
    }


        var dateNames = ["S",
                         "S",
                         "M",
                         "T",
                         "W",
                         "T",
                         "F",
    ]
    var senarios: [Senario] = CoreDataStack.shared.fetchSenarios()
    var weeklys: [Weekly] = []
    private let senarioConnection = SenarioConnection()

    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        self.segmentControl.selectedSegmentIndex = 0
        if self.senarioType == .senario {
            self.collectionView.alpha = 1.0
            self.tableView.alpha = 0.0
        }
        segmentControl.tintColor = Constant.Colors.green
        let attributes = [NSAttributedString.Key.font:UIFont.persianFont(size: 14)]
        segmentControl.setTitleTextAttributes(attributes, for: .normal)
        backBarButtonAttribute(color: .white, name: "")
        self.warningView.alpha = 0.0
        tableView.tableFooterView = UIView()
        NotificationCenter.default.addObserver(self, selector: #selector(endSenario), name: Constant.Notify.endSenario, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        NWSocketConnection.instance.delegate = self
        
        if senarioType == .weekly {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4) { [weak self] in
                guard let self = self else { return }
                self.fetchAllWeeklys()
            }
        }
    }

    @objc func endSenario() {
        self.warningView.alpha = 0.0
    }

    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        if senarioType == .senario {
            self.openSenarioVC()
        } else {
            self.openWeeklyVC()
        }
    }

    @IBAction func segmentControlValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.senarioType = .senario
        } else {
            self.senarioType = .weekly
        }
    }

    func openSenarioVC() {
        self.present(SenarioCommandViewController.create(senario: nil, completion: { [weak self] (senario) in
            guard let self = self else { return }
            if let _ = senario {
                self.senarios = CoreDataStack.shared.fetchSenarios()
                self.collectionView.reloadData()
            }
        }), animated: true, completion: nil)
    }

    func openWeeklyVC() {
        self.present(SenarioWeeklyViewController.create(completion: { [weak self] device in
            if let _ = device {
                self?.fetchAllWeeklys()
                DispatchQueue.main.asyncAfter(deadline: .now()+0) { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }), animated: true, completion: nil)
    }

    //PROTOCOLS
    func lognGestureTappedWeekly(sender: UILongPressGestureRecognizer, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            switch sender.state {
            case .possible:
                break
            case .began:
                let message = ""
                let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                    //
                }
                let remove = UIAlertAction.init(title: "Remove weekly schedule", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    self.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this weekly schedule?", buttonOneTitle: "Yes", buttonTwoTitle: "No", handlerButtonOne: { [weak self] in
                        guard let self = self else { return }
                        //*
                        let weekly = self.weeklys[indexPath.item]
                        self.senarioConnection.removeWeekly(code: UInt8(weekly.code), device: weekly.device)
                    }) {
                        //
                    }
                }
                remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")

                cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
                alertController.addAction(cancelAction)
                alertController.addAction(remove)
                if Password.shared.adminMode {
                    self.present(alertController, animated: true, completion: nil)
                }
            default:
                break
            }
        }
    }

    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadKitCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            switch sender.state {
            case .possible:
                break
            case .began:
                let message = "Do you want to change this scenario?"
//                let title = NSAttributedString(string: "Scenario changes", attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 17.0)!, NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.08911790699, green: 0.08914073557, blue: 0.08911494166, alpha: 1)])
//                let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.black])

                let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
//                alertController.setValue(attributeMsg, forKey: "attributedMessage")
//                alertController.setValue(title, forKey: "attributedTitle")
                let cancelAction = UIAlertAction.init(title:"Cancel", style: .cancel) { (action) in
                    //
                }
                let addShortcut = UIAlertAction.init(title: "Add Shortcut", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    let senario = self.senarios[indexPath.item]
                    let vc = ChooseRoomViewController.create { room in
                        if let room = room {
                            _ = CoreDataStack.shared.addEquipment(addToRoom: room, image: senario.cover ?? UIImage(named: "d22")!.pngData()!, name: senario.name ?? "No Name", type: Int64(9999), isShortcut: true, senarioId: Int(senario.id))
                            NotificationCenter.default.post(name: Notification.Name("someApplianceAdded"), object: nil)
                        }
                    }
                    
                    self.present(vc, animated: true)
                }
                let changeName = UIAlertAction.init(title: "Rename", style: .default) { [weak self] (action) in
                    self?.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                        //*
                        guard let self = self else { return }
                        if let equipments = CoreDataStack.shared.fetchEquipments(), let equipment = equipments.first(where: { eq in
                            eq.senarioId == self.senarios[indexPath.item].id && eq.isShortcut
                        }) {
                            CoreDataStack.shared.updateEquipment(name: name, eq: equipment)
                            NotificationCenter.default.post(name: Notification.Name("someApplianceAdded"), object: nil)
                        }
                        
                        CoreDataStack.shared.changeSenario(self.senarios[indexPath.item], name)
                        self.collectionView.reloadItems(at: [indexPath])
                    }
                }
                let editSenario = UIAlertAction.init(title: "Scenario Editing", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    self.present(SenarioCommandViewController.create(senario: self.senarios[indexPath.item], completion: { [weak self] (senario) in
                        guard let self = self else { return }
                        if let _ = senario {
                            //*
                            self.senarios = CoreDataStack.shared.fetchSenarios()
                            self.collectionView.reloadData()
                        }
                    }), animated: true, completion: nil)
                }
                let remove = UIAlertAction.init(title:"Delete Scenario", style: .default) { [weak self] (action) in
                    self?.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this scenario?", buttonOneTitle: "Yes", buttonTwoTitle: "No", handlerButtonOne: { [weak self] in
                        //*
                        guard let self = self else { return }
                        CoreDataStack.shared.removeSenario(self.senarios[indexPath.item])
                        self.senarios = CoreDataStack.shared.fetchSenarios()
                        self.collectionView.reloadData()
                    }) {
                        //
                    }
                }
                let internalSenario = UIAlertAction.init(title: "Assign to external scenario", style: .default) { [weak self] (action) in
                    guard let self = self else { return }

                    let vc = ModuleInputViewController.create(completion: { [weak self] (selectedItem) in
                        guard let selectedItem = selectedItem else { return }
                        guard let self = self else { return }
                        // CHECK OLD OR NEW SENARIO TYPE
                        SenarioSendDataV2Controller.run(viewController: self, self.senarios[indexPath.item]) { dict in
                            if let _ = dict {
                                let reapetedTime = self.senarios[indexPath.item].repeatedTime
                                self.senarioConnection.sendSenarioToDevice(viewController: self, senario: self.senarios[indexPath.item], selectedItem: selectedItem, runTimesCount: Int(reapetedTime))
                            } else {
                                self.senarioConnection.sendSenarioToDevice(viewController: self, senario: self.senarios[indexPath.item], selectedItem: selectedItem)
                            }
                        }
                    })
                    vc.isSwitch = true
                    self.present(vc, animated: true, completion: nil)
                }
                let internalSenarioRemote = UIAlertAction.init(title: "Assign to external scenario", style: .default) {[weak self] (action) in
                    guard let self = self else { return }
                    let vc = TimeViewController.create(lastTime: nil, type: .channel, completion: { [weak self] (number) in
                        guard let number = number else { return }
                        guard let self = self else { return }
                        // CHECK OLD OR NEW SENARIO TYPE
                        SenarioSendDataV2Controller.run(viewController: self, self.senarios[indexPath.item]) { dict in
                            if let _ = dict {
                                let reapetedTime = self.senarios[indexPath.item].repeatedTime
                                self.senarioConnection.sendSenarioToDeviceRemote(viewController: self, senario: self.senarios[indexPath.item], channel: Int(number), runTimesCount: Int(reapetedTime))
                            } else {
                                self.senarioConnection.sendSenarioToDeviceRemote(viewController: self, senario: self.senarios[indexPath.item], channel: Int(number))
                            }
                        }
                    })
                    
                    vc.channels = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
                    self.present(vc, animated: true, completion: nil)
                }
                let internalSenarioOthers = UIAlertAction.init(title:"Assign to external scenario", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    let vc = ModuleInputViewController.create(completion: { [weak self] (selectedItem) in
                        guard let self = self else { return }
                        guard let selectedItem = selectedItem else { return }
                        // CHECK OLD OR NEW SENARIO TYPE
                        SenarioSendDataV2Controller.run(viewController: self, self.senarios[indexPath.item]) { dict in
                            if let _ = dict {
                                let reapetedTime = self.senarios[indexPath.item].repeatedTime
                                self.senarioConnection.sendSenarioToDevice(viewController: self, senario: self.senarios[indexPath.item], selectedItem: selectedItem, runTimesCount: Int(reapetedTime))
                            } else {
                                self.senarioConnection.sendSenarioToDevice(viewController: self, senario: self.senarios[indexPath.item], selectedItem: selectedItem)
                            }
                        }
                    })
                    vc.isSwitch = false
                    self.present(vc, animated: true, completion: nil)
                }
                let changeIcon = UIAlertAction.init(title: "Change Icon", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    let item = self.senarios[indexPath.item]
                    let vc = PhotoPickupViewController.create {[weak self] data in
                        guard let self = self else { return }
                        if let data = data {
                            CoreDataStack.shared.updateSenario(cover: data, senario: item)
                            if let equipments = CoreDataStack.shared.fetchEquipments(), let equipment = equipments.first(where: { eq in
                                eq.senarioId == item.id && eq.isShortcut
                            }) {
                                CoreDataStack.shared.updateEquipment(cover: data, eq: equipment)
                                NotificationCenter.default.post(name: Notification.Name("someApplianceAdded"), object: nil)
                            }
                            self.collectionView.reloadData()
                        }
                    }
                    self.present(vc, animated: true)
                }
                
                alertController.addAction(changeIcon)
                cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
                alertController.addAction(cancelAction)
                alertController.addAction(changeName)
                alertController.addAction(addShortcut)
                
                changeIcon.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                changeName.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                addShortcut.setValue(UIColor.RADGreen, forKey: "titleTextColor")

                SenarioSendDataV2Controller.run(viewController: self, senarios[indexPath.item], completion: { [weak self] dict in
                    guard let self = self else { return }
                    if let dict = dict {
                        let deviceSerials = CoreDataStack.shared.fetchCommandOn(senario: self.senarios[indexPath.item]).map(\.deviceSerial)
                        var condition = false
                        if let devices = CoreDataStack.shared.devices {
                            devices.forEach { device in
                                if deviceSerials.contains(device.serial) {
                                    if device.version >= 15 {
                                        condition = true
                                    }
                                }
                            }
                        }
                        if condition {
                            let busSenario = UIAlertAction.init(title:"Assign to bus scenario", style: .default) { [weak self] (action) in
                                guard let self = self else { return }
                                
                                let vc = BusInputViewController.create { [weak self] (selectedItem, device) in
                                    guard let self = self else { return }
                                    guard let device = device, let selectedItem = selectedItem else { return }

                                    self.senarioConnection.sendBusSenario(viewController: self, senario: self.senarios[indexPath.item], selectedItem: selectedItem, dict: dict, bridgeDevice: device)
                                    
                                }
                                
                                self.present(vc, animated: true)
                            }
                            busSenario.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                            alertController.addAction(busSenario)
                        }
                    }
                })
                if SenarioSendDataController.iSAllCommandsSameDevice(senario: senarios[indexPath.item]) {
                    internalSenario.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(internalSenario)
                }
                if SenarioSendDataController.iSAllCommandsSameDeviceRemote(senario: senarios[indexPath.item]) {
                    internalSenarioRemote.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(internalSenarioRemote)
                }
                if SenarioSendDataController.iSAllCommandsSameDeviceRGBThermoAndDimmer(senario: senarios[indexPath.item]) {
                    internalSenarioOthers.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(internalSenarioOthers)
                }
                editSenario.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                alertController.addAction(editSenario)
                remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                alertController.addAction(remove)
                if Password.shared.adminMode {
                    self.present(alertController, animated: true, completion: nil)
                }
            default:
                break
            }
        }
    }

    func fetchWeeklyFor(device:Device) {
        senarioConnection.fetchWeeklyIn(device: device) { _ in }
    }

    func fetchAllWeeklys() {
        self.weeklys = []
        if let devices = CoreDataStack.shared.devices {
            devices.forEach { device in
                fetchWeeklyFor(device: device)
            }
        }
    }
}

extension SenarioMainViewController: UITableViewDelegate,UITableViewDataSource,RadkitWeeklyTableViewCellDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weeklys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
        cell.weeklyDelegate = self
        let weekly = weeklys[indexPath.row]
        if let deviceType = DeviceType.init(rawValue: Int(weekly.device.type)) {
            var serial = "\(weekly.device.serial)"
            if serial.count < 6 {
                while serial.count < 6 {
                    serial = "0" + serial
                }
            }
            cell.label_1.text = deviceType.changed() + "\(serial)"
            if deviceType.rawValue >= 10 {
                cell.imageViewOne.image = UIImage.init(named: "\(Int(deviceType.rawValue))")
            } else {
                cell.imageViewOne.image = UIImage.init(named: "0\(Int(deviceType.rawValue))")
            }
        }
        cell.label_2.text = weekly.name
        var hour = "\(weekly.hour)"
        var time = "\(weekly.time)"
        if hour.count == 1 {
            hour = "0" + hour
        }
        if time.count == 1 {
            time = "0" + time
        }
        cell.label_3.text = hour + ":" + time
        var isNoDay = true
        if weekly.days.contains(1) {
            isNoDay = false
        }
        if isNoDay {
            cell.labels.forEach { (label) in
                label.text = ""
            }
            cell.labels[0].text = "Just Once"
            cell.labels[0].textColor = Constant.Colors.green
        } else {
            for (index,label) in cell.labels.enumerated() {
                label.text = self.dateNames[index]
                if weekly.days[index] == 1 {
                    label.textColor = Constant.Colors.green
                } else {
                    label.textColor = .darkGray
                }
            }
        }
        return cell
    }
}

extension SenarioMainViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,RadKitCollectionViewCellDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return senarios.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RadKitCollectionViewCell
        cell.delegate = self
        let senario = senarios[indexPath.item]
        cell.label1.text = senario.name
        if let cover = senario.cover {
            cell.imageView1.image = UIImage(data: cover)
        } else {
            cell.imageView1.image = UIImage(named: "d22")
        }
        SenarioSendDataV2Controller.run(viewController: self, senarios[indexPath.item]) { dict in
            if dict != nil {
                cell.imageView2.image = UIImage(named: "new_sc")
            } else {
                cell.imageView2.image = UIImage(named: "old_sc")
            }
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.tag == 0 {
            return CGSize.init(width: collectionView.frame.width, height: collectionView.frame.height)
        } else {
            var numberOfColumns: CGFloat = 2
            if UIScreen.main.bounds.width > 320 {
                numberOfColumns = 3
            }
            let spaceBetweenCells: CGFloat = 10
            let padding: CGFloat = 40
            let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns
            return CGSize.init(width: cellDimention, height: 140.0)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView.tag == 0 {
            return 0
        } else {
            return 10
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // new or old?
        SenarioSendDataV2Controller.run(viewController: self, senarios[indexPath.item]) {[weak self] dict in
            guard let self = self else { return }
            if let dict = dict {
                self.count = 0
                for (key,value) in dict {
                    if let device = CoreDataStack.shared.devices?.first(where: { d in
                        d.serial == key
                    }) {
                        // data
                        var data = value
                        // add tedad ejra if needed
                        let reapetedTime = self.senarios[indexPath.item].repeatedTime
                        if reapetedTime != 0 {
                            data.append(UInt8(reapetedTime))
                        }
                        
                        NWSocketConnection.instance.send(tag: 48, device: device, typeRequest: .scenarioRequest,data: data, results: nil)
                        self.count += 1
                    }
                }
                if !dict.isEmpty {
                    ProgressHUD.show(nil, interaction: false)
                    self.perform(#selector(self.addedScenarioAllDeviceMsg), with: nil, afterDelay: 2)
                }
            } else {
                self.senarioConnection.runSenario(viewController: self, senario: self.senarios[indexPath.item]) { [weak self] (senarioRunType) in
                    guard let self = self else { return }
                    switch senarioRunType {
                    case .begin:
                        self.warningView.alpha = 0.74
                        self.warningTitleLabel.text = "Command 1 sent"
                        print(".begin senario")
                        break
                    case .last:
                        self.warningTitleLabel.text = "Last command sent"
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.2) { [weak self] in
                            guard let self = self else { return }
                            self.warningView.alpha = 0.0
                        }
                        print(".last senario")
                        break
                    case .enter(let index):
                        self.warningTitleLabel.text = "Command \(index + 1) sent"
                        print(".enter \(index) senario")
                        break
                    case .failed:
                        break
                    }
                }
            }
        }
    }
    
    @objc private func addedScenarioAllDeviceMsg() {
        if !self.allDevicesScenarioItems.isEmpty {
            let serials = self.allDevicesScenarioItems.joined(separator: ", ")
            var msg = ""
            
            if self.count == self.allDevicesScenarioItems.count {
                msg = "All devices received the scenario"
            } else {
                msg = "Device \(serials) received the scenario"
            }
            
            ProgressHUD.showSucceed(msg, interaction: false)

            self.allDevicesScenarioItems = []
            self.count = 0
        } else {
            self.count = 0
            let msg = "scenario not received, Please try again"
            ProgressHUD.showFailed(msg, interaction: false)
        }
    }
    
    private func dayByteToBit(byte:UInt8) -> [Int] {
        var intDays = [Int](repeating: 0, count: 8)
        let bits = Data.toBits(bytes: [byte])
        for (index,bit) in bits.enumerated() {
            if index < 8 {
                if bit == .one {
                    intDays[index] = 1
                }
            }
        }
        return intDays
    }
    
    private func bitsToByte(weeks:[Int]) -> UInt8 {
        var bits = [Data.Bit](repeating: .zero, count: 8)
        for (index,week) in weeks.enumerated() {
            if week == 1 {
                bits[index] = .one
            }
        }
        let byte0 = Data.bitsToBytes(bits: bits.reversed())[0]
        return byte0
    }
}
