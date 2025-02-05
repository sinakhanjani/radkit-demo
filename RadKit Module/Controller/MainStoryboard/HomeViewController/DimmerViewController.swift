//
//  DimmerViewController.swift
//  Master
//
//  Created by Sina khanjani on 10/18/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

class DimmerViewController: UIViewController, RadkitTableViewCellDelegate,ConfigAdminRolles {
    enum Section: Hashable {
        case main
    }
    
    enum Item: Hashable {
        case item(EQRely,[UInt8])
    }
    
    private var dataSource: UITableViewDiffableDataSource<Section,Item>!
    private var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    
    private func configureDataSource() {
        dataSource = .init(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
            guard let self = self else { return nil }
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
            cell.delegate = self
            if self.isSenario {
                if let items = self.eqRelays {
                    let item = items[indexPath.item]
                    cell.label_1.text = (item.name ?? "")
                    cell.label_2.text = "R\(Int(item.digit)+1)-S/\((item.eqDevice?.serial ?? 0))"
                    cell.slider1.setValue(0.0, animated: false)
                }
                if let selectedEqRelay = self.selectedEqRelays {
                    if selectedEqRelay.objectID == self.eqRelays![indexPath.item].objectID {
                        cell.roundedView1.borderColor = Constant.Colors.blue
                        cell.slider1.setValue(self.showSelected, animated: false)
                    } else {
                        cell.roundedView1.borderColor = .separator
                    }
                } else {
                    cell.slider1.setValue(0.0, animated: false)
                    cell.roundedView1.borderColor = .separator
                }
            } else {
                if let items = self.eqRelays {
                let item = items[indexPath.item]
                    cell.label_1.text = (item.name ?? "")
                    var serial = "\(item.eqDevice?.serial ?? 0)"
                    if serial.count < 6 {
                        while serial.count < 6 {
                            serial = "0" + serial
                        }
                    }
                    
                    cell.label_2.text = "R\(Int(item.digit)+1)-S/\(serial)"
                    let value = Float(self.datas[Int(item.eqDevice!.serial)]![indexPath.item])
                    cell.label_3.text = "\(Int((value/255)*100)) %"
                    if value > 0 {
                        cell.switchButton1.isOn = true
                    } else {
                        cell.switchButton1.isOn = false
                    }
                    cell.slider1.setValue(value, animated: true)
                }
                cell.roundedView1.borderColor = .separator
            }
            return cell
        })
    }
    
    private func createSnapshot() -> NSDiffableDataSourceSnapshot<Section,Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section,Item>()
        snapshot.appendSections([.main])
        if let eqRelays = self.eqRelays, !self.datas.isEmpty {
            let values = eqRelays.map { self.datas[Int($0.eqDevice!.serial)]! }
            var items = [Item]()
            for (index,item) in eqRelays.enumerated() {
                let ii = Item.item(item, values[index])
                items.append(ii)
            }

            snapshot.appendItems(items, toSection: .main)
        }
        
        return snapshot
    }
    
    private func reloadSnapshot() {
        snapshot = createSnapshot()
        dataSource.apply(snapshot,animatingDifferences: false)
    }
    
    var productID: String?
    
    func adminChanged() {
        self.admin()
    }
    
    // Senario
    private var completion: ((_ eqRelays: EQRely?,_ conditionForFirstThree:Bool?,_ items:[Int:UInt8]?) -> Void)?
    private var selectedEqRelays: EQRely?
    public var isSenario:Bool = false
    public var sendItems:[Int:UInt8]!
    public var sendCondition:Bool!
    public var showSelected:Float!
    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ conditionForFirstThree:Bool?,_ items:[Int:UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DimmerViewController") as! DimmerViewController
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
            completion?(selectedEqRelay,sendCondition,sendItems)
        } else {
            completion?(nil,nil,nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    var isSlider: Bool = false

    @IBOutlet weak var tableView: UITableView!

    var equipment: Equipment?
    var eqRelays: [EQRely]?
    var datas:[Int:[UInt8]] = [:]
    var income: [Int:[UInt8]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        adminAccess()
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
            fetchAllEQRelayInEquipment()
        } else {
            backBarButtonAttribute(color: .white, name: "")
            if let equipment = self.equipment {
                self.title = equipment.name
            }
            fetchAllEQRelayInEquipment()
        }
    }
    
    @IBAction func rightBarButtonTapped() {
        if let equipment = self.equipment {
            self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex,device, _) in
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
            eqRelays.forEach { (eqRelay) in
                self.datas.updateValue([UInt8](repeating: UInt8(0), count: eqRelays.count), forKey: Int(eqRelay.eqDevice!.serial))
            }
            self.reloadSnapshot()
        }
    }
    
    // PROTOCOL
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
//                    let title = NSAttributedString(string: "Delete Output", attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 17.0)!, NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.08911790699, green: 0.08914073557, blue: 0.08911494166, alpha: 1)])
//                    let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.black])

                    let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
//                    alertController.setValue(attributeMsg, forKey: "attributedMessage")
//                    alertController.setValue(title, forKey: "attributedTitle")
                    let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                        //
                    }
                    let changeName = UIAlertAction.init(title: "Rename", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays, let equipment = self.equipment {
                            self.presentAlertActionWithTextField(message: "Please enter the name", title: "Rename", textFieldPlaceHolder:"Write the name") { (name) in
                                CoreDataStack.shared.updateEQRelayName(eqRelay: items[indexPath.item], name: name)
                                self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
                                let x = self.datas
                                self.datas = [:]
                                self.reloadSnapshot()
                                self.datas = x
                                self.reloadSnapshot()
                            }
                        }
                    }
                    let remove = UIAlertAction.init(title: "Delete Output", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays {
                            self.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this output?", buttonOneTitle: "Yes", buttonTwoTitle: "No", handlerButtonOne: { [weak self] in
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
//                    remove.setValue(UIColor.black, forKey: "titleTextColor")
//                    changeName.setValue(UIColor.black, forKey: "titleTextColor")
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
    
    func slider1ValueChanged(sender: UISlider, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            cell.label_3.text = "\(Int((sender.value/255)*100)) %"
            if sender.value > 255 {
                cell.switchButton1.isOn = true
            } else {
                cell.switchButton1.isOn = false
            }
            if isSenario {
                guard let eqRelays = self.eqRelays else { return }
                var items = [Int:UInt8]()
                let key = Int(eqRelays[indexPath.item].digit)+1
                items.updateValue(UInt8(Int(sender.value)), forKey: key)
                let conditionForFirstThree = (key == 1 || key == 2 || key == 3) ? true:false
                self.sendCondition = conditionForFirstThree
                self.sendItems = items
                self.showSelected = sender.value
                self.selectedEqRelays = eqRelays[indexPath.item]
//                self.tableView.reloadData()
                self.reloadSnapshot()
            } else {
                guard let eqRelays = self.eqRelays else { return }
                guard let eqDevice = eqRelays[indexPath.item].eqDevice else { return }
                guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
                var items = [Int:UInt8]()
                let key = Int(eqRelays[indexPath.item].digit)+1
                items.updateValue(UInt8(Int(sender.value)), forKey: key)
                cell.roundedView1.borderColor = Constant.Colors.blue
                let conditionForFirstThree = (key == 1 || key == 2 || key == 3) ? true:false
                NWSocketConnection.instance.sendRequestDimmerOrRGB(tag:indexPath.item,device: device, typeRequest: .directRequest, items: items, isDimmer: true, isDaem: false, rgb: nil,isWithFirstThree: conditionForFirstThree) { [weak self] (device, bytes) in
//                    guard let bytes = bytes, let device = device else { return }
//                    self?.setDataToCorrectRelay(bytes: bytes, device: device,reloadTable: false, indexPath: indexPath)
                }
            }
        }
    }

    func switchButtonValueChanged(sender: UISwitch, cell: RadkitTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            guard let eqRelays = self.eqRelays else { return }
            guard let eqDevice = eqRelays[indexPath.item].eqDevice else { return }
            guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) else { return }
            var items = [Int:UInt8]()
            let key = Int(eqRelays[indexPath.item].digit)+1
            
            if sender.isOn {
                // has a data in sloder : value>0
                items.updateValue(UInt8(Int(255)), forKey: key)
                cell.slider1.setValue(255, animated: false)
            } else {
                items.updateValue(UInt8(Int(0)), forKey: key)
                cell.slider1.setValue(0, animated: false)
            }
            
            cell.label_3.text = "\(Int((cell.slider1.value/255)*100)) %"
            cell.roundedView1.borderColor = Constant.Colors.blue
            let conditionForFirstThree = (key == 1 || key == 2 || key == 3) ? true:false
            NWSocketConnection.instance.sendRequestDimmerOrRGB(tag: 501,device: device, typeRequest: .directRequest, items: items, isDimmer: true, isDaem: false, rgb: nil,isWithFirstThree: conditionForFirstThree) { [weak self] (device, bytes) in
                guard let self = self else { return }
//                guard let bytes = bytes, let device = device else { return }
//                self.setDataToCorrectRelay(bytes: bytes, device: device)
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
            
        } else {
            NWSocketConnection.instance.delegate = self
            sendBeginData()
            self.timer?.invalidate()
            self.timer = nil
            if let equipment = self.equipment, let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true, block: { [weak self] (timer) in
                            guard let self = self else { return }
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
                        NWSocketConnection.instance.send(tag:502,device: device, typeRequest: .stateRequest,parameterRequest:.presnetRequest) { [weak self] (bytes,device) in
//                            guard let device = device, let bytes = bytes else { return }
//                            self?.setDataToCorrectRelay(bytes: bytes,device: device)
                        }
                    }
                }
            }
        }
    }

    func setDataToCorrectRelay(bytes: [UInt8], device:Device, reloadTable: Bool = true, indexPath: IndexPath? = nil) {
        guard !bytes.isEmpty else { return }
        var data = bytes
        guard data.count>=11 &&  data.count<=12 else { return }
        data.removeFirst()
        guard let eqRelays = self.eqRelays else { return }
        for (index,eqRelay) in eqRelays.enumerated() {
            if let eqDevice = eqRelay.eqDevice {
                if eqDevice.serial == device.serial {
                    let i = Int(eqRelay.digit)
                    self.datas[Int(device.serial)]![index] = data[i]
                }
            }
        }
        
        income.updateValue(Array(data[0...5]), forKey: Int(device.serial))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let indexPath = indexPath, !reloadTable {
                self.reloadSnapshot()
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            } else {
                self.reloadSnapshot()
            }
        }
    }
}



extension DimmerViewController :UITableViewDelegate {
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.eqRelays?.count ?? 0
//    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
//        cell.delegate = self
//        if isSenario {
//            if let items = self.eqRelays {
//                let item = items[indexPath.item]
//                cell.label_1.text = (item.name ?? "")
//                cell.label_2.text = "R\(Int(item.digit)+1)-S/\((item.eqDevice?.serial ?? 0))"
//                cell.slider1.setValue(0.0, animated: false)
//            }
//            if let selectedEqRelay = self.selectedEqRelays {
//                if selectedEqRelay.objectID == self.eqRelays![indexPath.item].objectID {
//                    cell.roundedView1.borderColor = Constant.Colors.blue
//                    cell.slider1.setValue(showSelected, animated: false)
//                } else {
//                    cell.roundedView1.borderColor = .separator
//                }
//            } else {
//                cell.slider1.setValue(0.0, animated: false)
//                cell.roundedView1.borderColor = .separator
//            }
//        } else {
//            if let items = self.eqRelays {
//            let item = items[indexPath.item]
//                cell.label_1.text = (item.name ?? "")
//                cell.label_2.text = "R\(Int(item.digit)+1)-S/\((item.eqDevice?.serial ?? 0))"
//                let value = Float(self.datas[Int(item.eqDevice!.serial)]![indexPath.item])
//                cell.label_3.text = "\(Int((value/255)*100)) %"
//                if value > 0 {
//                    cell.switchButton1.isOn = true
//                } else {
//                    cell.switchButton1.isOn = false
//                }
//                cell.slider1.setValue(value, animated: true)
//            }
//            cell.roundedView1.borderColor = .separator
//        }
//
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let eqRelays = self.eqRelays else { return }
        var items = [Int:UInt8]()
        let key = Int(eqRelays[indexPath.item].digit)+1
        items.updateValue(UInt8(0.0), forKey: key)
        let conditionForFirstThree = (key == 1 || key == 2 || key == 3) ? true:false
        self.sendCondition = conditionForFirstThree
        self.sendItems = items
        self.selectedEqRelays = eqRelays[indexPath.item]
        self.showSelected = 0.0
//        self.tableView.reloadData()
        self.reloadSnapshot()
    }
}

extension DimmerViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        if tag < 499 {
            guard let bytes = bytes, let device = device else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device,reloadTable: false, indexPath: IndexPath(item: tag, section: 0))
        }
        if tag == 501 {
            guard let bytes = bytes, let device = device else { return }
            self.setDataToCorrectRelay(bytes: bytes, device: device)
        }

        if tag == 502 {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes,device: device)
        }
        if tag == 1111 && dict?["hearth"] == nil {
            guard let device = device, let bytes = bytes else { return }
            self.setDataToCorrectRelay(bytes: bytes,device: device)
        }
    }
}
