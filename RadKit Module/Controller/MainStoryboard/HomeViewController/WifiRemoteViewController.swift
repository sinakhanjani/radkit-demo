//
//  WifiRemoteViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/19/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//

import UIKit

extension WifiRemoteViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- WifiRemote")
        if tag == 421 {
            guard let device = device, var bytes = bytes else {
                return
            }
            guard let index = dict?["index"] as? Int, let isLeft = dict?["isLeft"] as? Bool else { return }
            bytes.removeFirst()
            guard bytes.count > 1 else { return } // SINA
            let count = bytes[1]
            let size = bytes[0]
            bytes.removeFirst()
            bytes.removeFirst()
            func seprateBytes(bytes: [UInt8],count:Int,size:Int) -> [[UInt8]] {
                var end = [[UInt8]]()
                var added = [UInt8]()
                for index in 1..<bytes.count+1 {
                    added.append(bytes[index-1])
                    if index % size == 0 {
                        end.append(added)
                        added.removeAll()
                    }
                }
                return end
            }
            let seprated = seprateBytes(bytes: bytes, count: Int(count), size: Int(size))
            print("ALL DATA BY SEPRATED:",seprateBytes(bytes: bytes, count: Int(count), size: Int(size)))
//                guard let eqRelay = self.eqRelays?[index] else {
//                    return
//                }
            guard !seprated.isEmpty else { return }
            switch count {
            case 1:
                if isLeft {
                    self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
                } else {
                    self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[0])
                }
            case 2:
                self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
                self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[1])
            case 4:
                self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
                self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[1])
                self.eqRelays?[index].data3 = self.convertToData(bytes: seprated[2])
                self.eqRelays?[index].data4 = self.convertToData(bytes: seprated[3])
            case 6:
                self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
                self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[1])
                self.eqRelays?[index].data3 = self.convertToData(bytes: seprated[2])
                self.eqRelays?[index].data4 = self.convertToData(bytes: seprated[3])
                self.eqRelays?[index].data5 = self.convertToData(bytes: seprated[4])
                self.eqRelays?[index].data6 = self.convertToData(bytes: seprated[5])
            default:
                break
            }
            CoreDataStack.shared.saveContext()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print(index,"indexRecieved")
                self.fetchAllEQRelayInEquipment()
            }
            print("DONE SEND TO REMOTE",bytes,device.serial)
        }
        
        if tag == 502 {
            DispatchQueue.main.async {
                self.tableVIew.reloadData()
            }
        }
    }
}

class WifiRemoteViewController: UIViewController,RadkitTableViewCellDelegate,ConfigAdminRolles {
    
    deinit {
        print("deinit wifi remoteVC")
    }
    
    func adminChanged() {
        self.admin()
    }

    enum Side {
        case left,right,none
    }
    private var completion: ((_ eqRelays: EQRely?,_ data:[UInt8]?,_ name: String) -> Void)?
    private var selectedEqRelays: EQRely?
    public var isSenario:Bool = false
    var sendItem: [UInt8]?
    var selectedIndexPath: IndexPath?
    var side: Side = .none
    var selectedName:String = ""

    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ data:[UInt8]?,_ name: String) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WifiRemoteViewController") as! WifiRemoteViewController
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
        if let selectedEqRelay = self.selectedEqRelays, let data = self.sendItem {
            var endData = [UInt8(data.count)]
            endData.append(contentsOf: data)
            selectedEqRelay.name = selectedName
            self.completion?(selectedEqRelay,endData,selectedName) // **
            CoreDataStack.shared.saveContext()
            self.dismiss(animated: true, completion: nil)
        } else {
            self.presentIOSAlertWarning(message: "Please select a learned remote") {}
        }
    }
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //////???
    var equipment: Equipment?
    var eqRelays: [EQRely]?

    @IBOutlet weak var tableVIew: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))
//            rightfBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(cancelButtonTapped))
//            leftBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen
        } else {
            if let equipment = self.equipment {
                self.title = equipment.name
            }
        }
        fetchAllEQRelayInEquipment()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            self.tableVIew.reloadData()
        }
    }
    
    func fetchRowIn(Section: Int) -> Int? {
        if let eqRelays = self.eqRelays {
            if eqRelays.count >= Section {
                let digit = Int(eqRelays[Section].digit)
                if digit == 0 {
                    return 1
                }
                if digit == 1 {
                    return 1
                }
                if digit == 2 {
                    return 2
                }
                if digit == 3 {
                    return 3
                }
            }
        }
        return nil
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        if !isSenario {
            if let equipment = self.equipment {
                self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex,device, _) in
                    guard let self = self else { return }
                    if let equipment = self.equipment, let device = device, let selectedIndex = selectedIndex {
                        let index = selectedIndex[0]
                        CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: [Int64(index)])
                        self.fetchAllEQRelayInEquipment()
                    }
                }), animated: true, completion: nil)
            }
        }
    }
    
    
    func learnRemote(eqRelay:EQRely,index:Int,data:Data,isLeft:Bool) {
        let activityView = UIView(frame: UIScreen.main.bounds)
        activityView.backgroundColor = .black
        activityView.alpha = 0.6
        let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityIndicator.startAnimating()
        activityView.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: view.bounds.width  / 2,y: view.bounds.height / 2)
        TwoActionViewController.create(viewController: self, title: "", subtitle: "Put the switch in the learning mode according to the relevant guide and select the learn button.", completionHandlerButtonOne: {
            print("CANCELED TAPPED")
        }) {
            self.sendFirstStepToRemote(index: index, data: data)
            self.view.addSubview(activityView)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+5.0) {
                // aya yadgiri be dorosti anjam shod? // send req&
                activityView.removeFromSuperview()
                AcceptLearnViewController.create(viewController: self, title: "", subtitle: "Did the learning go well?", completionHandlerButtonOne: {
                    //CANCELLLED
                }) {
                    let sendByte = [UInt8(6)]
                    var inputBytes: [UInt8] = sendByte
                    let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                    let data = Data.init(referencing: nsdata)
                    self.sendToRemote(data: data, type: .otherRequest, index: index, isLeft: isLeft)
                }
            }
        }
    }
    
    func sendFirstStepToRemote(index:Int,data:Data) {
        guard let equipment = self.equipment else {
            return
        }
        guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
            return
        }
        guard !eqDevices.isEmpty else {
            return
        }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: (eqRelays?[index].eqDevice ?? eqDevices[0])) else {
            return
        }
        NWSocketConnection.instance.send(device: device, typeRequest: .otherRequest,data: data.bytes) { (bytes, device) in
            guard let _ = device, var _ = bytes else {
                return
            }
        }
    }
    
    func sendToRemote(data:Data,type:TypeRequest,index:Int,isLeft:Bool) {
        guard let equipment = self.equipment else {
            return
        }
        guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
            return
        }
        guard !eqDevices.isEmpty else {
            return
        }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: (eqRelays?[index].eqDevice ?? eqDevices[0])) else {
            return
        }
        if type == .otherRequest {
            print("SEEND:",data.bytes)
            NWSocketConnection.instance.send(dict: ["index":index, "isLeft": isLeft] ,tag: 421, device: device, typeRequest: type,data: data.bytes) { [weak self] (bytes, device) in
//                guard let self = self else { return }
//                guard let device = device, var bytes = bytes else {
//                    return
//                }
//                bytes.removeFirst()
//                guard bytes.count > 1 else { return } // SINA
//                let count = bytes[1]
//                let size = bytes[0]
//                bytes.removeFirst()
//                bytes.removeFirst()
//                func seprateBytes(bytes: [UInt8],count:Int,size:Int) -> [[UInt8]] {
//                    var end = [[UInt8]]()
//                    var added = [UInt8]()
//                    for index in 1..<bytes.count+1 {
//                        added.append(bytes[index-1])
//                        if index % size == 0 {
//                            end.append(added)
//                            added.removeAll()
//                        }
//                    }
//                    return end
//                }
//                let seprated = seprateBytes(bytes: bytes, count: Int(count), size: Int(size))
//                print("ALL DATA BY SEPRATED:",seprateBytes(bytes: bytes, count: Int(count), size: Int(size)))
////                guard let eqRelay = self.eqRelays?[index] else {
////                    return
////                }
//                guard !seprated.isEmpty else { return }
//                switch count {
//                case 1:
//                    if isLeft {
//                        self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
//                    } else {
//                        self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[0])
//                    }
//                case 2:
//                    self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
//                    self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[1])
//                case 4:
//                    self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
//                    self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[1])
//                    self.eqRelays?[index].data3 = self.convertToData(bytes: seprated[2])
//                    self.eqRelays?[index].data4 = self.convertToData(bytes: seprated[3])
//                case 6:
//                    self.eqRelays?[index].data = self.convertToData(bytes: seprated[0])
//                    self.eqRelays?[index].data2 = self.convertToData(bytes: seprated[1])
//                    self.eqRelays?[index].data3 = self.convertToData(bytes: seprated[2])
//                    self.eqRelays?[index].data4 = self.convertToData(bytes: seprated[3])
//                    self.eqRelays?[index].data5 = self.convertToData(bytes: seprated[4])
//                    self.eqRelays?[index].data6 = self.convertToData(bytes: seprated[5])
//                default:
//                    break
//                }
//                CoreDataStack.shared.saveContext()
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    print(index,"indexRecieved")
//                    self.fetchAllEQRelayInEquipment()
//                }
//                print("DONE SEND TO REMOTE",bytes,device.serial)
            }
        } else {
            // direct*
            NWSocketConnection.instance.send(device: device, typeRequest: type,data: data.bytes) { [weak self] (bytes, device) in
                guard let self = self else { return }
                guard let device = device, var bytes = bytes else {
                    return
                }
            }
        }
    }
    
    func canLearn(eqRelay:EQRely,isLeft: Bool?) -> Bool {
        let digit = Int64(eqRelay.digit)
        var condition = false
        switch digit {
        case 0:
            if isLeft! {
                condition = eqRelay.data == nil ? true:false
            } else {
                condition = eqRelay.data2 == nil ? true:false
            }
        case 1:
            condition = eqRelay.data2 == nil ? true:false
        case 2:
            condition = eqRelay.data4 == nil ? true:false
        case 3:
            condition = eqRelay.data6 == nil ? true:false
        default:
            return false
        }
        print("condition",condition)
        return condition
    }
    
    func convertToData(bytes:[UInt8])  ->Data {
        let sendByte = bytes
        var inputBytes: [UInt8] = sendByte
        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
        let data = Data.init(referencing: nsdata)
        return data
    }
    
    // ______ DELEGATE ______
    func button1Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableVIew.indexPath(for: cell) {
            //sabz
            if let eqRelays = self.eqRelays {
                let item = eqRelays[indexPath.section]
                if isSenario {
                    var rData: Data?
                    let digit = Int(item.digit)
                    let row = indexPath.row
                    switch digit {
                    case 0:
                        rData = item.data
                        self.selectedName = item.name2 ?? "General"
                    case 1:
                        rData = item.data
                        self.selectedName = item.name2 ?? "TC2-1"
                    case 2:
                        if row == 0 {
                            rData = item.data
                            self.selectedName = item.name2 ?? "TC2-2"
                        }
                        if row == 1 {
                            rData = item.data3
                            self.selectedName = item.name3 ?? "TC2-2"
                        }
                    case 3:
                        if row == 0 {
                            rData = item.data
                            self.selectedName = item.name2 ?? "TC2-3"
                        }
                        if row == 1 {
                            rData = item.data3
                            self.selectedName = item.name3 ?? "TC2-3"
                        }
                        if row == 2 {
                            self.selectedName = item.name4 ?? "TC2-3"
                            rData = item.data5
                        }
                    default:
                        break
                    }
                    self.sendItem = rData?.bytes
                    self.selectedIndexPath = indexPath
                    self.side = .left
                    self.selectedEqRelays = item
                    self.tableVIew.reloadData()
                } else {
                    if canLearn(eqRelay: item, isLeft: true) {
                        var mo = 0
                        let digit = Int(item.digit)
                        switch digit {
                        case 0:
                            mo = 2
                        case 1:
                            mo = 3
                        case 2:
                            mo = 4
                        case 3:
                            mo = 5
                        default:
                            break
                        }
                        let sendByte = [UInt8(mo)]
                        print("DIGIT:\(digit),mo:\(mo)")
                        var inputBytes: [UInt8] = sendByte
                        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                        let data = Data.init(referencing: nsdata)
                        self.learnRemote(eqRelay: item, index: indexPath.section, data: data, isLeft: true)
                    } else {
                        // send direct reqyest
                        var rData: Data?
                        let digit = Int(item.digit)
                        let row = indexPath.row
                        switch digit {
                        case 0:
                            rData = item.data
                        case 1:
                            rData = item.data
                        case 2:
                            if row == 0 {
                                rData = item.data
                            }
                            if row == 1 {
                                rData = item.data3
                            }
                        case 3:
                            if row == 0 {
                                rData = item.data
                            }
                            if row == 1 {
                                rData = item.data3
                            }
                            if row == 2 {
                                rData = item.data5
                            }
                        default:
                            break
                        }
                        if let rData = rData {
                            cell.button1.setBackgroundImage(UIImage(named: "click_blue"), for: .normal)
                            self.sendDirect(data: rData, index: indexPath.section)
                        }
                    }
                }
            }
        }
    }
    func button2Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableVIew.indexPath(for: cell) {
            //sabz
            if let eqRelays = self.eqRelays {
                let item = eqRelays[indexPath.section]
                if isSenario {
                    var rData: Data?
                    let digit = Int(item.digit)
                    let row = indexPath.row
                    switch digit {
                    case 0:
                        rData = item.data2
                        self.selectedName = item.name2 ?? "General"
                    case 1:
                        rData = item.data2
                        self.selectedName = item.name2 ?? "TC2-1"
                    case 2:
                        //1,3:
                        if row == 0 {
                            rData = item.data2
                            self.selectedName = item.name2 ?? "TC2-2"
                        }
                        if row == 1 {
                            rData = item.data4
                            self.selectedName = item.name3 ?? "TC2-2"
                        }
                    case 3:
                        if row == 0 {
                            rData = item.data2
                            self.selectedName = item.name2 ?? "TC2-3"
                        }
                        if row == 1 {
                            rData = item.data4
                            self.selectedName = item.name3 ?? "TC2-3"
                        }
                        if row == 2 {
                            self.selectedName = item.name4 ?? "TC2-3"
                        }
                    default:
                        break
                    }
                    self.sendItem = rData?.bytes
                    self.side = .right
                    self.selectedIndexPath = indexPath
                    self.selectedEqRelays = item
                    self.tableVIew.reloadData()
                } else {
                    if canLearn(eqRelay: item, isLeft: false) {
                        var mo = 0
                        let digit = Int(item.digit)
                        switch digit {
                        case 0:
                            mo = 2
                        case 1:
                            mo = 3
                        case 2:
                            mo = 4
                        case 3:
                            mo = 5
                        default:
                            break
                        }
                        let sendByte = [UInt8(mo)]
                        print("DIGIT:\(digit),mo:\(mo)")
                        var inputBytes: [UInt8] = sendByte
                        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                        let data = Data.init(referencing: nsdata)
                        self.learnRemote(eqRelay: item, index: indexPath.section, data: data, isLeft: false)
                    } else {
                        // send direct reqyest
                        var rData: Data?
                        let digit = Int(item.digit)
                        let row = indexPath.row
                        switch digit {
                        case 0:
                            rData = item.data2
                        case 1:
                            rData = item.data2
                        case 2:
                            //1,3:
                            if row == 0 {
                                rData = item.data2
                            }
                            if row == 1 {
                                rData = item.data4
                            }
                        case 3:
                            if row == 0 {
                                rData = item.data2
                            }
                            if row == 1 {
                                rData = item.data4
                            }
                            if row == 2 {
                                rData = item.data6
                            }
                        default:
                            break
                        }
                        if let rData = rData {
                            cell.button2.setBackgroundImage(UIImage(named: "click_blue"), for: .normal)
                            self.sendDirect(data: rData, index: indexPath.section)
                        }
                    }
                }
            }
        }
    }
    
    func button3Tapped(sender: UIButton, cell: RadkitTableViewCell) {
        if let indexPath = tableVIew.indexPath(for: cell) {
            //.//.//.//.//.//
        }
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadkitTableViewCell) {
        if isSenario {
            
        } else {
            guard let eqRelays = self.eqRelays else { return }
            if let indexPath = tableVIew.indexPath(for: cell) {
//                let item = eqRelays[indexPath.section]
                switch sender.state {
                case .possible:
                    break
                case .began:
                    print(indexPath)
                    let message = "Remote settings"
//                    let title = NSAttributedString(string: "Remove Remote", attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 17.0)!, NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.08911790699, green: 0.08914073557, blue: 0.08911494166, alpha: 1)])
//                    let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.black])

                    let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
//                    alertController.setValue(attributeMsg, forKey: "attributedMessage")
//                    alertController.setValue(title, forKey: "attributedTitle")
                    let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                        //
                    }
                    let changeName = UIAlertAction.init(title: "Rename", style: .default) { [weak self] (action) in
                        if let items = self?.eqRelays {
                            self?.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                                switch indexPath.row {
                                case 0:
                                    items[indexPath.section].name2 = name
                                case 1:
                                    items[indexPath.section].name3 = name
                                case 2:
                                    items[indexPath.section].name4 = name
                                default:
                                    break
                                }
                                CoreDataStack.shared.saveContext()
                                self?.tableVIew.reloadData()
                            }
                        }
                    }
                    let remove = UIAlertAction.init(title:"Remove Remote", style: .default) { [weak self] (action) in
                        if let items = self?.eqRelays {
                            self?.presentIOSAlertWarningWithTwoButton(message:"Do you want to delete this remote?", buttonOneTitle:"Yes", buttonTwoTitle:"No", handlerButtonOne: { [weak self] in
                                CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: items[indexPath.section])
                                self?.fetchAllEQRelayInEquipment()
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
    
    // SEND DIRECT
    func sendDirect(data:Data,index:Int) {
        guard let equipment = self.equipment else {
            return
        }
        guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
            return
        }
        guard !eqDevices.isEmpty else {
            return
        }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: (eqRelays?[index].eqDevice ?? eqDevices[0])) else {
            return
        }
        let byte = data.bytes
        let size = UInt8(data.count)
        var sendBytes = [size]
        sendBytes.append(contentsOf: byte)
        print(sendBytes,"DIRECT SEND")
        NWSocketConnection.instance.send(tag:502, device: device, typeRequest: .directRequest,data: sendBytes) { [weak self] (bytes, device) in
            guard let _ = device, var _ = bytes else {
                return
            }
//            DispatchQueue.main.async {
//                self?.tableVIew.reloadData()
//            }
        }
    }

}

extension WifiRemoteViewController:UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.eqRelays?.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchRowIn(Section: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
        cell.delegate = self
        if let eqRelays = self.eqRelays {
            let item = eqRelays[indexPath.section]
            var serial = "\(item.eqDevice?.serial ?? 0)"
            if serial.count < 6 {
                while serial.count < 6 {
                    serial = "0" + serial
                }
            }
            
            cell.label_2.text = "S/" + "\(serial)"
            var title: String!
            switch item.digit {
            case 0:
                title = item.name2 ?? "General"
            case 1:
                title = item.name2 ?? "TC2-1"
            case 2:
                if indexPath.row == 0 {
                    title = item.name2 ?? "TC2-2"
                }
                if indexPath.row == 1 {
                    title = item.name3 ?? "TC2-2"
                }
            case 3:
                if indexPath.row == 0 {
                    title = item.name2 ?? "TC2-3"
                }
                if indexPath.row == 1 {
                    title = item.name3 ?? "TC2-3"
                }
                if indexPath.row == 2 {
                    title = item.name4 ?? "TC2-3"
                }
            default:
                title = item.name2 ?? ""
            }
            if isSenario {
                if let selectedIndexPath = self.selectedIndexPath {
                    if selectedIndexPath == indexPath {
                        switch self.side {
                        case .left:
                            cell.button1.setBackgroundImage(UIImage(named: "click_blue"), for: .normal)
                            cell.button2.setBackgroundImage(UIImage(named: "click_red"), for: .normal)
                        case .right:
                            cell.button2.setBackgroundImage(UIImage(named: "click_blue"), for: .normal)
                            cell.button1.setBackgroundImage(UIImage(named: "click_green"), for: .normal)
                        default:
                            cell.button2.setBackgroundImage(UIImage(named: "click_red"), for: .normal)
                            cell.button1.setBackgroundImage(UIImage(named: "click_green"), for: .normal)
                        }
                    } else {
                        cell.button2.setBackgroundImage(UIImage(named: "click_red"), for: .normal)
                        cell.button1.setBackgroundImage(UIImage(named: "click_green"), for: .normal)
                    }
                } else {
                    cell.button2.setBackgroundImage(UIImage(named: "click_red"), for: .normal)
                    cell.button1.setBackgroundImage(UIImage(named: "click_green"), for: .normal)
                }
            } else {
                cell.button2.setBackgroundImage(UIImage(named: "click_red"), for: .normal)
                cell.button1.setBackgroundImage(UIImage(named: "click_green"), for: .normal)
            }
            cell.label_1.text = title
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
