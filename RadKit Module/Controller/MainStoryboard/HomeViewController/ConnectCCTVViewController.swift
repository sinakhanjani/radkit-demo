//
//  ConnectCCTVViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/25/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit

class ConnectCCTVViewController: UIViewController {

    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    var completion: ((_ ip:String, _ username: String,_ password: String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func doneBUttonTapped(_ sender: Any) {
        guard !ipTextField.text!.isEmpty else {
            self.presentIOSAlertWarning(message: "Please enter the ip address.", completion: {})
            return
        }

        if self.usernameTextField.text!.isEmpty && self.passwordTextField.text!.isEmpty {
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.completion?(self.ipTextField.text!,self.usernameTextField.text!,self.passwordTextField.text!)
            }
        }
        if !self.usernameTextField.text!.isEmpty && !self.passwordTextField.text!.isEmpty {
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.completion?(self.ipTextField.text!,self.usernameTextField.text!,self.passwordTextField.text!)
            }
        }
        
        if !self.usernameTextField.text!.isEmpty && self.passwordTextField.text!.isEmpty {
            self.presentIOSAlertWarning(message: "If your device has a username and password, enter the both Login/Password field", completion: {})
        }
        if self.usernameTextField.text!.isEmpty && !self.passwordTextField.text!.isEmpty {
            self.presentIOSAlertWarning(message: "If your device has a username and password, enter the both Login/Password field", completion: {})
        }
        
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }

    static func create(completion: ((_ ip:String, _ username: String,_ password: String) -> Void)?) -> ConnectCCTVViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ConnectCCTVViewController") as! ConnectCCTVViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        
        return vc
    }
}
