//
//  InputViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 11/8/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

struct SectionInputStatus {
    let items: [InputStatus]
    let title: String
}

protocol InputStatusViewControllerDelegate: AnyObject {
    func inputStatusVCDismiised()
}

class InputViewController: UIViewController, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        if tag == 151 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard var data = bytes else { return }
                // Senario: First 2 bytes, Daem: Secend Two Bytes.
                // [10, 15, 255, 0, 0] //Header: 10 || Senario: 15, 255 || Daem: 0, 0
                data.removeFirst()
                self.updateUI(data: data)
            }
        }
    }
    
    
    @IBOutlet var switchs: [UISwitch]!
    @IBOutlet var bgView: UIView!

    var device: Device!
    
    weak var delegate: InputStatusViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NWSocketConnection.instance.delegate = self
        // Do any additional setup after loading the view.
        print("number of switchs:\(switchs.count)")
        getStatus()
        switchs.forEach { (element) in
            element.addTarget(self, action: #selector(switchsValueChanged(_:)), for: .valueChanged)
        }
    }

    
    @objc func switchsValueChanged(_ sender: UISwitch) {
        var data: [UInt8] = []
        
        for (index,value) in switchs.enumerated() {
            if value == sender {
                let itemNumber = index + 1
                data.append(UInt8(itemNumber))
                let sit = value.isOn ? UInt8(0):UInt8(1)
                data.append(sit)
            }
        }
        sendRequest(data)
    }
    
    func getStatus() {
        sendRequest([0,0])
    }
    
    func updateUI(data: [UInt8]) {
        let senarioSection = Data.toBits(bytes: [data[0],data[1]])//
        let situationSection = Data.toBits(bytes: [data[2],data[3]])
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.bgView.backgroundColor = .systemGroupedBackground
            for (index,item) in self.switchs.enumerated() {
                if index < 16 {
                    item.isOn = senarioSection[index] ==  Data.Bit.one ? false: true
                } else {
                    item.isOn = situationSection[index - 16] == Data.Bit.one ? false: true
                }
            }
        }
    }
    
    func sendRequest(_ sendData: [UInt8]) {
        bgView.backgroundColor = Constant.Colors.blue
        NWSocketConnection.instance.send(tag:151, device: self.device, typeRequest: .otherRequest3,data: sendData) { [weak self] (data, device) in
//            guard let self = self else { return }
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                guard var data = data else { return }
//                // Senario: First 2 bytes, Daem: Secend Two Bytes.
//                // [10, 15, 255, 0, 0] //Header: 10 || Senario: 15, 255 || Daem: 0, 0
//                data.removeFirst()
//                self.updateUI(data: data)
//            }
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: { [weak self] in
            self?.delegate?.inputStatusVCDismiised()
        })
    }
    
    static func create() -> InputViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "InputViewController") as! InputViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
}
