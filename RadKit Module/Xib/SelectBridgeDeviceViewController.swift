//
//  SelectBridgeDeviceViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/2/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import DropDown

class SelectBridgeDeviceViewController: UIViewController {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var deviceButton: RoundedButton!

    private var completion: ((_ device: Device?) -> Void)?
    private let deviceDropButton = DropDown()
    var selectedDevice: Device?
    var dataSource = [Device]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let touch = UITapGestureRecognizer(target: self, action: #selector(tapped))
        bgView.addGestureRecognizer(touch)

        if let devices = CoreDataStack.shared.devices?.filter({ item in
            print(item.version, item.type)
            return (Int(item.version) >= 15) && (Int(item.type) < 50) && !item.isBossDevice
        }).uniqued() {
            self.dataSource = devices
        }
        
        deviceDropButton.dataSource = dataSource.map { item in
            if let devType = DeviceType.init(rawValue: Int(item.type)) {
                return devType.changed() + "\(item.serial)"
            }
            return ""
        }
        deviceDropButton.anchorView = deviceButton
        deviceDropButton.bottomOffset = CGPoint(x: 0, y: deviceButton.bounds.height)
        deviceDropButton.textFont = UIFont.persianFont(size: 14.0)
        
        self.deviceDropButton.selectionAction = { (index, item) in
            self.deviceButton.setTitle(item, for: .normal)
            self.selectedDevice = self.dataSource[index]
        }
        
        if let selectedDevice = selectedDevice {
            if let devType = DeviceType.init(rawValue: Int(selectedDevice.type)) {
                self.deviceButton.setTitle(devType.changed() + "\(selectedDevice.serial)", for: .normal)
            }
        }
    }

    @objc func tapped() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        self.completion?(selectedDevice)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectButtonTapped(_ sender: Any) {
        deviceDropButton.show()
    }
    
    static func create(completion: ((_ selectedItem: Device?) -> Void)?) -> SelectBridgeDeviceViewController {
        let vc = SelectBridgeDeviceViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        
        return vc
    }
}
