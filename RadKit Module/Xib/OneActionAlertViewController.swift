//
//  OneActionAlertViewController.swift
//  Master
//
//  Created by Sinakhanjani on 4/22/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import UIKit

class OneActionAlertViewController: UIViewController, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        if tag == 12 {
            guard let bytes = bytes, let device = device else {
                return
            }
            guard let vc = dict?["vc"] as? OneActionAlertViewController, let equipment = dict?["equipment"] as? Equipment, let digit = dict?["digit"] as? Int64 else {
                return
            }
            var isCustom: EQRely?
            if let fromIsCustom = dict?["isCustom"] as? EQRely {
                isCustom = fromIsCustom
            }
            var res = bytes
            res.removeFirst()
            var inputBytes: [UInt8] = res
            let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
            let data = Data.init(referencing: nsdata)
            if let eqRelay = isCustom {
                eqRelay.data = data
                CoreDataStack.shared.saveContext()
            } else {
                CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: [digit],data: data)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.completionHandler?(res)
                vc.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    private var subtitle: String?
    private var detail: String?
    private var completionHandler: ((_ bytes: [UInt8]?) -> Void)?
    var myDevice:Device?
    var isFromSenario = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let subtitle = subtitle, let detail = detail {
            self.subtitleLabel.text = subtitle
            self.detailLabel.text = detail
        }
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+15.0) {
//            vc.dismiss(animated: false) { () -> Void in
//                //
//            }
//        } // CHANGE TO COMMENT AND ADD TO LINE 56 1399/08/01
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }

    @IBAction func doneButtonTapped(_ sender: RoundedButton) {
        dismiss(animated: false) { () -> Void in
            self.completionHandler?(nil)
            if let device = self.myDevice {
                if !self.isFromSenario {
                    NWSocketConnection.instance.send(device: device, typeRequest: .otherRequest,data: [UInt8(1)]) { (data, device) in
                        //
                    }
                } else {
                    NWSocketConnection.instance.send(device: device, typeRequest: .otherRequest,data: [UInt8(7)]) { (data, device) in
                        //
                    }
                }
            }
        }
    }
    
    static func create(viewController: UIViewController, title: String?, subtitle: String?,device:Device,digit:Int64,equipment:Equipment,isCustom:EQRely?=nil, completionHandler: ((_ bytes: [UInt8]?) -> Void)?) {
        let vc = OneActionAlertViewController()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.subtitle = title
        vc.detail = subtitle
        vc.completionHandler = completionHandler
        viewController.view.endEditing(true)
        viewController.present(vc, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.6) {
            vc.send(equipment:equipment,device: device,digit: digit, vc: vc,isCustom: isCustom)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+15.0) {
            vc.dismiss(animated: false) { () -> Void in
                //
            }
        }
    }
    
    static func create2(viewController: UIViewController,device:Device, isFromSenario: Bool) -> OneActionAlertViewController {
        let vc = OneActionAlertViewController()
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overCurrentContext
        vc.myDevice = device
        vc.isFromSenario = isFromSenario
        viewController.view.endEditing(true)
        viewController.present(vc, animated: true, completion: nil)

        return vc
    }
    
    func send(equipment:Equipment,device: Device,digit:Int64,vc: OneActionAlertViewController,isCustom:EQRely?=nil) {
        var dict: [String: Any] = ["device": device, "vc": vc, "equipment":equipment, "digit": digit]
        if let isCustom = isCustom {
            dict.updateValue(isCustom, forKey: "isCustom")
        }
        NWSocketConnection.instance.send(dict: dict,tag: 12,device: device, typeRequest: .otherRequest,data: [UInt8(1)]) { [weak self] (bytes, device) in
//            guard let self = self else { return }
//            guard let bytes = bytes, let device = device else {
//                return
//            }
//            var res = bytes
//            res.removeFirst()
//            var inputBytes: [UInt8] = res
//            let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
//            let data = Data.init(referencing: nsdata)
//            if let eqRelay = isCustom {
//                eqRelay.data = data
//                CoreDataStack.shared.saveContext()
//            } else {
//                CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: [digit],data: data)
//            }
//            print(digit,"DIGIT")
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.completionHandler?(res)
//                vc.dismiss(animated: true, completion: nil)
//            }
        }
    }
    
    deinit {
        print("ONEACTIONVC DEINIT")
    }
}
