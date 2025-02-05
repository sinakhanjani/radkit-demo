//
//  TvRemoteViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/19/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//

import UIKit

extension TvRemoteViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- TV")
        if (tag == 1) {
//            guard let self = self else { return }
            guard let device = device, let bytes = bytes else {
                return
            }
            guard let type = dict?["type"] as? TypeRequest else { return }
            if type == .directRequest {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.view.backgroundColor = .systemGroupedBackground
                    self.vs[0].borderColor = .systemBackground
                }
            }
            print("DONE SEND TO REMOTE",bytes,device.serial)
        }
    }
}

class TvRemoteViewController: UIViewController,NumberPadViewControllerDelegate,ConfigAdminRolles {
        
    func adminChanged() {
        self.admin()
    }
    
    func senarioReturn(data: [UInt8]?, eqRelay: EQRely?) {
        self.selectedEqRelays = eqRelay
        self.sendItem = data
    }
    private var completion: ((_ eqRelays: EQRely?,_ data:[UInt8]?) -> Void)?
    public var selectedEqRelays: EQRely?
    public var isSenario:Bool = false
    var sendItem: [UInt8]?

    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ data:[UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TvRemoteViewController") as! TvRemoteViewController
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
            var endData = data
            endData.remove(at: 1)
            self.completion?(selectedEqRelay,endData) // **
            self.dismiss(animated: true, completion: nil)
        } else {
            self.updateUI()
            self.presentIOSAlertWarning(message: "Please select a learned remote") {}
        }
    }
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //??????
    @IBOutlet var vs: [RoundedView]!
    @IBOutlet var remoteButtons: [RoundedButton]!
    @IBOutlet weak var buttonsStackView: UIStackView!
    
    var equipment: Equipment?
    var eqRelays: [EQRely]?
    var estimatedTime: Double = 0
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        self.vs[0].borderColor = .systemBackground

        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))
            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(cancelButtonTapped))
            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen
            self.fetchAllEQRelayInEquipment()
            self.updateUI()
        } else {
            if let equipment = self.equipment {
                self.title = equipment.name
                addUILongPressGestureRecognizer()
                self.fetchAllEQRelayInEquipment()
                updateUI()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }
    
    //////
    func returnFromNumberPad() {
        NWSocketConnection.instance.delegate = self
        fetchAllEQRelayInEquipment()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? NumberPadViewController {
            destination.eqRelays = eqRelays
            destination.equipment = equipment
            destination.delegate = self
            destination.isSenario = self.isSenario
            destination.tvRemoteViewController = self
        }
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            if let eqRelays = self.eqRelays, !eqRelays.isEmpty {
                self.buttonsStackView.alpha = 1.0
            } else {
                self.buttonsStackView.alpha = 0.0
            }
        }
        updateUI()
    }
    
    func updateUI() {
        self.remoteButtons.forEach { (button) in
            button.alpha = 1.0//0.22
            button.imageView?.alpha = 0.22
            button.titleLabel?.alpha = 0.22
        }
        guard let eqRelays = self.eqRelays else { return }
        for eqRelay in eqRelays {
            eqRelay.name = self.equipment?.name
            if eqRelay.digit < 99 {
                self.remoteButtons[Int(eqRelay.digit)].alpha = 1.0
                self.remoteButtons[Int(eqRelay.digit)].imageView?.alpha = 1.0
                self.remoteButtons[Int(eqRelay.digit)].titleLabel?.alpha = 1.0

            }
            if eqRelay.digit >= 100 {
                self.remoteButtons[12].alpha = 1.0 // 123 button index
                self.remoteButtons[12].imageView?.alpha = 1.0 // 123 button index
                self.remoteButtons[12].titleLabel?.alpha = 1.0 // 123 button index
            }
        }
        CoreDataStack.shared.saveContext()
    }
    
    func addUILongPressGestureRecognizer() {
        for (index,button) in remoteButtons.enumerated() {
            let touch = CustomUILongPressGestureRecognizer(target: self, action: #selector(lognGestureTapped(_:)), tag: index)
            button.addGestureRecognizer(touch)
        }
    }
    
    @objc func lognGestureTapped(_ sender: CustomUILongPressGestureRecognizer) {
        switch sender.state {
        case .possible:
            break
        case .began:
            break
        case .changed:
            break
        case .ended:
            for (index,button) in remoteButtons.enumerated() {
                if index == sender.tag {
                    button.imageView?.alpha = 0.22
                    button.titleLabel?.alpha = 0.22
                    if let eqRelays = eqRelays {
                        for eqRelay in eqRelays {
                            if eqRelay.digit == Int64(index) {
                                self.learnRemote(index: index,isCustom: eqRelay)
                                button.imageView?.alpha = 1
                                button.titleLabel?.alpha = 1
                                return
                            }
                        }
                    }
                }
            }
            break
        case .cancelled:
            break
        case .failed:
            break
        default:
            break
        }
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        if !isSenario {
            if let equipment = self.equipment {
                self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self]
                    (selectedIndex,device, _) in
                    guard let self = self else { return }
                    if let equipment = self.equipment, let device = device, let _ = selectedIndex {
                        if let eqRelays = self.eqRelays, !eqRelays.isEmpty {
                            eqRelays.forEach { (eqRelay) in
                                eqRelay.digit = 99
                                CoreDataStack.shared.saveContext()
                            }
                        } else {
                            CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: [99])
                        }
                        self.fetchAllEQRelayInEquipment()
                    }
                }), animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func remoteButtonsTapped(_ sender: UIButton) {
        if isSenario {
            guard let eqRelays = self.eqRelays else {
                return
            }
            for (index,button) in remoteButtons.enumerated() {
                if button == sender {
                    guard index != 12 else {
                        self.performSegue(withIdentifier: NumberPadViewController.segue, sender: nil)
                        return
                    }
                    var data:Data?
                    for eqRelay in eqRelays {
                        if eqRelay.digit == Int64(index) {
                            data = eqRelay.data
                            self.selectedEqRelays = eqRelay
                            break
                        }
                    }
                    self.sendItem = data?.bytes
                    button.backgroundColor = Constant.Colors.blue
                } else {
                    if index == 5 {
                        button.backgroundColor = .clear
                    } else {
                        button.backgroundColor = #colorLiteral(red: 0.8549019608, green: 0.8588235294, blue: 0.8784313725, alpha: 1)
                    }
                }
            }
            self.updateUI()
        } else {
            for (index,button) in remoteButtons.enumerated() {
                if button == sender {
                    self.learnButtons(index: index,iSForce: false)
                }
            }
        }
    }
    
    func learnButtons(index:Int,iSForce:Bool) {
        guard let eqRelays = self.eqRelays else { return }
        if index == 12 {
            self.performSegue(withIdentifier: NumberPadViewController.segue, sender: nil)
            return
        }
        var isContain = false
        var data:Data?
        for eqRelay in eqRelays {
            if eqRelay.digit == Int64(index) {
                isContain = true
                data = eqRelay.data
                break
            }
        }
        if isContain {
            if iSForce {
                self.learnRemote(index: index,isForce:iSForce)
            } else {
                if let data = data {
                    // send actionRequest*
                    self.sendToRemote(data: data, type: .directRequest)
                }
            }
        } else {
            self.learnRemote(index: index)
        }
    }

    func learnRemote(index:Int,isForce: Bool = false, isCustom: EQRely? = nil) {
        TwoActionViewController.create(viewController: self, title: "Learning", subtitle: "After hitting the learn button, hold the remote in front of the device and press the desired button", completionHandlerButtonOne: { [weak self] in
            guard let self = self else { return }
            //cancel//
            self.updateUI()
        }) { [weak self] in
            guard let self = self else { return }
            // yadgiri
            guard let equipment = self.equipment else {
                return
            }
            guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
                return
            }
            guard !eqDevices.isEmpty else {
                return
            }
            guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevices[0]) else {
                return
            }
            OneActionAlertViewController.create(viewController: self, title:"Learning", subtitle: "Please press the remote button",device: device,digit: Int64(index),equipment: equipment, isCustom: isCustom) { [weak self] bytes in
                // waiting for button until 15secend*
                // cancel request *
                guard let self = self else { return }
                if bytes == nil {
                    let sendByte = [UInt8(7)]
                    var inputBytes: [UInt8] = sendByte
                    let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                    let data = Data.init(referencing: nsdata)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.updateUI()
                    }
                    self.sendToRemote(data: data, type: .otherRequest)
                } else {
                    NWSocketConnection.instance.delegate = self
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.fetchAllEQRelayInEquipment()
                    }
                }
            }
        }
    }
    
    func sendToRemote(data:Data,type:TypeRequest) {
        guard let equipment = self.equipment else {
            return
        }
        guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
            return
        }
        guard !eqDevices.isEmpty else {
            return
        }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevices[0]) else {
            return
        }
        var sendBytes = data.bytes
        if sendBytes.count > 1 {
            sendBytes.remove(at: 1)
        }
        if type == .directRequest {
            self.view.backgroundColor = Constant.Colors.blue
            self.vs[0].borderColor = Constant.Colors.blue
        }
        print(sendBytes,"SENDBYTE")
        NWSocketConnection.instance.send(dict: ["type":type], tag: 1, device: device, typeRequest: type,data: sendBytes, results: nil)
    }
    
    deinit {
        
    }
}
