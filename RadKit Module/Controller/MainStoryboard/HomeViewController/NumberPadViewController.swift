//
//  NumberPadViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/27/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//

import UIKit

protocol NumberPadViewControllerDelegate: AnyObject {
    func returnFromNumberPad()
    func senarioReturn(data:[UInt8]?,eqRelay:EQRely?)
}

class NumberPadViewController: UIViewController, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- NUMBERPAD")
        if (tag == 2) {
            guard let device = device, let bytes = bytes else {
                return
            }
            guard let type = dict?["type"] as? TypeRequest else { return }
            if type == .directRequest {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.keyView.backgroundColor = .systemGroupedBackground
                }
            }
            print("DONE SEND TO REMOTE",bytes,device.serial)
        }
        
    }
    
    static let segue = "toNumberPadSegue"
    weak var delegate: NumberPadViewControllerDelegate?
    public var isSenario:Bool = false

    @IBOutlet weak var keyView: RoundedView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet var remoteButtons: [RoundedButton]!
    
    var tvRemoteViewController: TvRemoteViewController?
    
    var eqRelays: [EQRely]?
    var equipment: Equipment?
    var estimatedTime: Double = 0
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isSenario {
            fetchAllEQRelayInEquipment()
            updateUI()
        } else {
            let touch = UITapGestureRecognizer(target: self, action: #selector(tapped))
            bgView.addGestureRecognizer(touch)
            addUILongPressGestureRecognizer()
            fetchAllEQRelayInEquipment()
            updateUI()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }
    
    func addUILongPressGestureRecognizer() {
         for (index,button) in remoteButtons.enumerated() {
             let touch = CustomUILongPressGestureRecognizer(target: self, action: #selector(lognGestureTapped(_:)), tag: index+100)
             button.addGestureRecognizer(touch)
         }
     }
     
     @objc func lognGestureTapped(_ sender: CustomUILongPressGestureRecognizer) {
         switch sender.state {
         case .possible:
             break
         case .began:
//             if let eqRelays = self.eqRelays {
//                 eqRelays.forEach { (eqRelay) in
//                     if eqRelay.digit == Int64(sender.tag) {
//                         self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] (timer) in
//                             guard let self = self else { return }
//                             self.estimatedTime += 0.2
//                             print(self.estimatedTime)
//                             if self.estimatedTime >= 4.0 {
//                                 self.learnButtons(index: sender.tag,iSForce: true)
//                                 self.timer?.invalidate()
//                                 self.estimatedTime = 0.0
//                             }
//                         })
//                     }
//                 }
//             }
             break
         case .changed:
             break
         case .ended:
             for (index,button) in remoteButtons.enumerated() {
                 if index+100 == sender.tag {
                     button.imageView?.alpha = 0.22
                     button.titleLabel?.alpha = 0.22
                     if let eqRelays = eqRelays {
                         for eqRelay in eqRelays {
                             if eqRelay.digit == Int64(index+100) {
                                 self.learnRemote(index: index+100,isCustom: eqRelay)
                                 button.imageView?.alpha = 1
                                 button.titleLabel?.alpha = 1
                                 return
                             }
                         }
                     }
                 }
             }
             break
//             self.estimatedTime = 0.0
//             self.timer?.invalidate()
         case .cancelled:
             break
         case .failed:
             break
         default:
             break
         }
     }
    
    @objc func tapped() {
        delegate?.returnFromNumberPad()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        delegate?.returnFromNumberPad()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func remoteButtonsTapped(_ sender: UIButton) {
        if isSenario {
            guard let eqRelays = self.eqRelays else {
                return
            }
            for (index,button) in remoteButtons.enumerated() {
                if button == sender {
                    var data:Data?
                    var eq:EQRely?
                    for eqRelay in eqRelays {
                        if eqRelay.digit == Int64(index+100) {
                            data = eqRelay.data
                            eq = eqRelay
                            break
                        }
                    }
                    self.delegate?.senarioReturn(data: data?.bytes, eqRelay: eq)
                    button.backgroundColor = Constant.Colors.blue
                } else {
                    button.backgroundColor = #colorLiteral(red: 0.8549019608, green: 0.8588235294, blue: 0.8784313725, alpha: 1)
                }
            }
            self.updateUI()
        } else {
            for (index,button) in remoteButtons.enumerated() {
                if button == sender {
                    self.learnButtons(index: index+100,iSForce: false)
                }
            }
        }
    }

    func updateUI() {
        self.remoteButtons.forEach { (button) in
            button.alpha = 1.0
            button.imageView?.alpha = 0.22
            button.titleLabel?.alpha = 0.22
        }
        guard let eqRelays = self.eqRelays else { return }
        for eqRelay in eqRelays {
            eqRelay.name = self.equipment?.name
            if eqRelay.digit != 99 && eqRelay.digit >= 100 {
                print("AVAILABLE",eqRelay.digit)
                self.remoteButtons[Int(eqRelay.digit-100)].alpha = 1.0
                self.remoteButtons[Int(eqRelay.digit-100)].imageView?.alpha = 1.0
                self.remoteButtons[Int(eqRelay.digit-100)].titleLabel?.alpha = 1.0
            }
        }
        CoreDataStack.shared.saveContext()
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            updateUI()
        }
    }
    
    func learnButtons(index:Int,iSForce:Bool) {
        guard let eqRelays = self.eqRelays else { return }
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
            print("ISCONTAIN")
            if iSForce {
                self.learnRemote(index: index,isForce:iSForce)
            } else {
                //useData
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
            //cancel//
            guard let self = self else { return }
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
            OneActionAlertViewController.create(viewController: self, title: "Learning", subtitle: "Please press the remote button",device: device,digit: Int64(index),equipment: equipment, isCustom: isCustom) { [weak self] bytes in
                // waiting for button until 15secend*
                // cancel request *
                guard let self = self else { return }
                self.updateUI()
                if bytes == nil {
                    let sendByte = [UInt8(7)]
                    var inputBytes: [UInt8] = sendByte
                    let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                    let data = Data.init(referencing: nsdata)
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
            keyView.backgroundColor = Constant.Colors.blue
        }
        print("FINAL SEND:\(sendBytes)")
        NWSocketConnection.instance.send(dict: ["type":type], tag: 2,device: device, typeRequest: type,data: sendBytes) { [weak self] (bytes, device) in
//            guard let self = self else { return }
//            guard let device = device, let bytes = bytes else {
//                return
//            }
//            if type == .directRequest {
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    self.keyView.backgroundColor = .systemGroupedBackground
//                }
//            }
//            print("DONE SEND TO REMOTE",bytes,device.serial)
        }
    }
}
