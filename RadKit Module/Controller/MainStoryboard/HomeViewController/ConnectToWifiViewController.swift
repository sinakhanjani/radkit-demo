//
//  ConnectToWifiViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/25/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit

class ConnectToWifiViewController: UIViewController, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        // direct request
        if tag == 121 {
            if let bytes = bytes {
                if let fByte = bytes.first, fByte == UInt8(12) {
                    if bytes.count > 1 {
                        if bytes[1] == UInt8(0) {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                self.presentIOSAlertWarning(message: "The information has been received. Please re-enter the application after the device indicator is fixed", completion: { [weak self] in
                                    self?.dismiss(animated: true)
                                })
                            }
                        }
                    }
                }
            }
        }

    }
    
    @IBOutlet weak var wifiPasswordTextField: UITextField!
    @IBOutlet weak var wifiSSIDTextField: UITextField!
    
    var device: Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NWSocketConnection.instance.delegate = self
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func donTapped(_ sender: Any) {
        guard !self.wifiPasswordTextField.text!.isEmpty && !self.wifiSSIDTextField.text!.isEmpty else {
            self.presentIOSAlertWarning(message: "Please enter the wifi ssid and wifi password", completion: {})
            return
        }
        let sendData = "\(self.wifiSSIDTextField.text!)~\(self.wifiPasswordTextField.text!)~".utf8
        if let device = device {
            NWSocketConnection.instance.send(tag:121, device: device, typeRequest: .updateDeviceInfo, data: Array(sendData), results: nil)
        }
    }
    
    static func create(device: Device) -> ConnectToWifiViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ConnectToWifiViewController") as! ConnectToWifiViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.device = device
        return vc
    }
}
