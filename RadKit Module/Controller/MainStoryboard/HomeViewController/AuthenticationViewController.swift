//
//  AuthenticationViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 11/1/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    
    var completion: ((_ ok:Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.dismissedKeyboardByTouch()
        passwordTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
        
    // Action
    @IBAction func agreeButtonTapped(_ sender: Any) {
        view.endEditing(true)
        guard let password = passwordTextField.text, password != "" else {
            let faMessage = "Enter your password"
//            self.completion?(false)
            self.presentIOSAlertWarning(message: faMessage) {
                //
            }
            return
        }
        if Password.shared.currentPassword == password {
            self.completion?(true)
            self.dismiss(animated: true, completion: nil)
        } else {
            let faMessage = "Password is incorrect"
            self.completion?(false)
            presentIOSAlertWarning(message: faMessage) {
                //
            }
        }
    }
//
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.completion?(false)
        dismiss(animated: true, completion: nil)
    }
    
    static func create(completion: ((_ ok:Bool) -> Void)?) -> AuthenticationViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AuthenticationViewControllerID") as! AuthenticationViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        return vc
    }
}
