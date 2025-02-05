//
//  InputStatusViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/10/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit

class InputStatusViewController: UIViewController, ConfigAdminRolles, NWSocketConnectionDelegate {
    func adminChanged() {
        self.admin()
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var equipment: Equipment?
    var eqRelays: [EQRely]?
    
    private var selectedEqRelays: EQRely?
    private var completion: ((_ eqRelays: EQRely?, _ sendData: [UInt8]?) -> Void)?
    public var isSenario:Bool = false
    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?, _ sendData: [UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InputStatusViewController") as! InputStatusViewController
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
            let isOn = selectedEqRelay.state! == 0 ? false:true
            let channelNo = Int(selectedEqRelay.digit)+1+12
            let sendData: [UInt8] = [UInt8(channelNo),UInt8(isOn ? 1:0)]
            completion?(selectedEqRelays,sendData)
            // HATMAN STATE BAD AZ SABT SHODAN DAR COREDATA BADI NIL SHAVAD *** *** ***
            self.eqRelays?.forEach({ (eqRelay) in
                eqRelay.state = nil
            })
        } else {
            completion?(nil,nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonTapped() {
        self.eqRelays?.forEach({ (eqRelay) in
            eqRelay.state = nil
        })
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.adminAccess()
        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))

            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(cancelButtonTapped))
            
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen

            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            self.fetchAllEQRelayInEquipment()
        } else {
            backBarButtonAttribute(color: .label, name: "")
            if let equipment = self.equipment {
                self.title = equipment.name
            }
            fetchAllEQRelayInEquipment()
            // Do any additional setup after loading the view.
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        if isSenario {
            //
        } else {
            if let equipment = self.equipment {
                self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex,device, _) in
                    guard let self = self else { return }
                    if let equipment = self.equipment, let device = device, let selectedIndex = selectedIndex {
                        let int64 = selectedIndex.map { Int64($0) }
                        CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: int64)
                        self.fetchAllEQRelayInEquipment()
                        self.sendBeginReq()
                    }
                }), animated: true, completion: nil)
            }
        }
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            collectionView.reloadData()
        }
    }
    
    func sendBeginReq() {
        if let equipment = self.equipment {
            if let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        NWSocketConnection.instance.send(tag: 50, device: device, typeRequest: .otherRequest4, results: nil)
                    }
                }
            }
        }
    }
    
    func updateUI(device: Device, data: [UInt8]) {
        var digits = data
        let fByte = digits.removeFirst()
        guard fByte == UInt8(11) else { return }
        let bits = Data.toBits(bytes: digits)
        print("device:\(device.serial),", bits)
        if let eqDevice = CoreDataStack.shared.findEQDeviceInDevice(device: device, equipment: self.equipment) {
            if let eqRelays = CoreDataStack.shared.fetchEQRelaysIn(equipmentEQDevice: eqDevice) {
                let _ = eqRelays.map { $0.digit }
                let states = CoreDataStack.shared.findBitsEqualToEQDevicesDatabase(equipmentEQDevice: eqDevice, bits: bits)
                changeStateForEQRelays(eqRelays: eqRelays, states: states)
                DispatchQueue.main.async { [weak self] in
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    func changeStateForEQRelays(eqRelays:[EQRely],states: [Int]) {
        for (index,_) in eqRelays.enumerated() {
            eqRelays[index].state = states[index] == 0 ? 0:1
        }
    }
    
    func changeStateRelayToEmpty() {
        if let eqRelays = self.eqRelays {
            eqRelays.forEach { (eqRelay) in
                eqRelay.state = nil
            }
            CoreDataStack.shared.saveContext()
        }
    }

    // --- DEVICE CONNECTION ---
    private(set) var timer: Timer?
    
    deinit {
        print("SWITCH VC Deinit")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isSenario {
            
        } else {
            self.timer?.invalidate()
            self.timer = nil
            changeStateRelayToEmpty()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isSenario {
            
        } else {
            NWSocketConnection.instance.delegate = self
            sendBeginReq()
            self.timer?.invalidate()
            self.timer = nil
            if let equipment = self.equipment, let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) {
                eqDevices.forEach { (eqDevice) in
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevice) {
                        self.timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true, block: { (_) in
                            NWSocketConnection.mqttSubscriber(device: device, results: nil)
                        })
                    }
                }
            }
        }
    }
    
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("Input/Status, TAG: \(tag)")
        
        if tag == 50 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let data = bytes, let device = device else { return }
                self.updateUI(device: device, data: data)
            }
        }
        
        if (dict?["mqttSubscriber"] != nil) && (tag == 1111) {
            if let device = device, let bytes = bytes {
                self.updateUI(device: device, data: bytes)
            }
            return // qablan faqat return dasht
        }
        
        if (tag == 1111) && (dict?["hearth"] == nil) { // 0.6 secend run time tcp and mqtt
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let data = bytes, let device = device else { return }
                self.updateUI(device: device, data: data)
            }
            return
        }
    }
}

extension InputStatusViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RadKitCollectionViewCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.eqRelays?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "centerMainCollectionView", for: indexPath) as! RadKitCollectionViewCell
        cell.delegate = self

        if isSenario {
            if let items = self.eqRelays {
                let item = items[indexPath.item]
                if let cover = item.cover {
                    cell.button1.setBackgroundImage(UIImage(data: cover), for: .normal)
                } else {
                    cell.button1.setBackgroundImage(UIImage(named: "d1"), for: .normal)
                }
                
                var serial = "\(item.eqDevice?.serial ?? 0)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                cell.label1.text = "R\(Int(item.digit)+1)-S/\(serial)"
                cell.label2.text = item.name
                
                if let selectedEqRelay = self.selectedEqRelays {
                    if selectedEqRelay.objectID == self.eqRelays![indexPath.item].objectID {
                        self.eqRelays![indexPath.item].state = selectedEqRelay.state
                        let isOn = (selectedEqRelay.state! == 0 ? false:true)
                        cell.roundedView2.backgroundColor = isOn ? UIColor.baseGreen: UIColor.red
                    } else {
                        self.eqRelays![indexPath.item].state = 0
                        cell.roundedView2.backgroundColor = .systemGray
                    }
                } else {
                    self.eqRelays![indexPath.item].state = 0
                }
            }
        } else {
            cell.roundedView2.backgroundColor = .systemGray
            
            if let items = self.eqRelays {
                let item = items[indexPath.item]
                if let cover = item.cover {
                    cell.button1.setBackgroundImage(UIImage(data: cover), for: .normal)
                } else {
                    cell.button1.setBackgroundImage(UIImage(named: "d19"), for: .normal)
                }
                var serial = "\(item.eqDevice?.serial ?? 0)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                cell.label1.text = "R\(Int(item.digit)+1)-S/\(serial)"
                cell.label2.text = item.name
                
                if item.state != nil {
                    let isOn = (item.state! == 0 ? false:true)
                    cell.roundedView2.backgroundColor = isOn ? UIColor.baseGreen:UIColor.red
                } else {
                    cell.roundedView2.backgroundColor = .darkGray
                }
            }
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numberOfColumns: CGFloat = 2
        if UIScreen.main.bounds.width > 320 {
            numberOfColumns = 3
        }
        let spaceBetweenCells: CGFloat = 10
        let padding: CGFloat = 40
        let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns
        
        return CGSize.init(width: cellDimention, height: 128)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadKitCollectionViewCell) {
        if isSenario {
            //
        } else {
            guard let eqRelays = self.eqRelays else { return }
            if let indexPath = collectionView.indexPath(for: cell) {
                let item = eqRelays[indexPath.item]
                switch sender.state {
                case .possible:
                    break
                case .began:
                    print(indexPath)
                    let message = "Do you want to delete this output?"
                    let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
                    //                        alertController.setValue(attributeMsg, forKey: "attributedMessage")
                    //                        alertController.setValue(title, forKey: "attributedTitle")
                    let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                        //
                    }
                    let changeName = UIAlertAction.init(title:"Rename", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays {
                            self.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                                CoreDataStack.shared.updateEQRelayName(eqRelay: items[indexPath.item], name: name)
                                self?.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    }
                    let remove = UIAlertAction.init(title: "Delete", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays {
                            self.presentIOSAlertWarningWithTwoButton(message:"Do you want to delete this output?", buttonOneTitle:"Yes", buttonTwoTitle:"No", handlerButtonOne: {
                                CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: items[indexPath.item])
                                self.fetchAllEQRelayInEquipment()
                            }) {
                                //
                            }
                        }
                    }
                    let changeIcon = UIAlertAction.init(title: "Change Icon", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays {
                            let item = items[indexPath.item]
                            let vc = PhotoPickupViewController.create {[weak self] data in
                                guard let self = self else { return }
                                if let data = data {
                                    CoreDataStack.shared.updateEQRelay(cover: data, eqRelay: item)
                                    self.collectionView.reloadData()
                                }
                            }
                            self.present(vc, animated: true)
                        }
                    }
                    changeIcon.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(changeIcon)
                    cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
                    alertController.addAction(cancelAction)
                    changeName.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(changeName)
                    remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(remove)
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
    
    // PROTOCOL
    func button1Tapped(sender: UIButton, cell: RadKitCollectionViewCell) {
        if isSenario {
            guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
            if let _ = self.eqRelays {
                let next = self.eqRelays![indexPath.item].state! == 0 ? 1:0
                self.eqRelays![indexPath.item].state = NSNumber(value: next)
                self.selectedEqRelays = self.eqRelays![indexPath.item]
                self.collectionView.reloadData()
            }
        } else {
            ////
        }
    }
}
