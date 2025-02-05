//
//  PasswordViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 11/1/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

protocol PasswordViewControllerDelegate {
    func passwordSet()
}

class PasswordViewController: UIViewController {

    @IBOutlet weak var curerntPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var repeatedPasswordTextField: UITextField!
    
    var completion: ((_ ok:Bool) -> Void)?
    var currentPassword: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.dismissedKeyboardByTouch()
        self.currentPassword = Password.shared.currentPassword
        if Password.shared.currentPassword == nil {
            self.curerntPasswordTextField.isEnabled = false
            self.curerntPasswordTextField.backgroundColor = .gray
        } else {
            self.curerntPasswordTextField.isEnabled = true
            self.curerntPasswordTextField.backgroundColor = .clear
        }
    }
    
    @IBAction func agreeButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
        guard !self.newPasswordTextField.text!.isEmpty && !self.repeatedPasswordTextField.text!.isEmpty else {
            self.presentIOSAlertWarning(message: "Please enter a new password", completion: {})
            return
        }
        if let currentPassword = self.currentPassword {
            guard !self.curerntPasswordTextField.text!.isEmpty else {
                self.presentIOSAlertWarning(message: "Please enter the current password", completion: {})
                return
            }
            if self.curerntPasswordTextField.text! == currentPassword {
                if self.newPasswordTextField.text! == self.repeatedPasswordTextField.text! {
                    if currentPassword != self.newPasswordTextField.text! {
                        Password.shared.currentPassword = self.newPasswordTextField.text!
                        self.presentIOSAlertWarning(message: "Password changed successfully.") {
                            UserDefaults.standard.set(self.newPasswordTextField.text!, forKey: "MY_OLD_PASS")
                            NotificationCenter.default.post(name: Constant.Notify.updatePassword, object: nil)
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        self.presentIOSAlertWarning(message: "The old password is the same as the new password, please choose another password.", completion: {})
                    }
                } else {
                    self.presentIOSAlertWarning(message:"The passwords entered are not the same!") {}
                }
            } else {
                self.presentIOSAlertWarning(message:"Current password is incorrect", completion: {})
            }
        } else {
            if self.newPasswordTextField.text! == self.repeatedPasswordTextField.text! {
                Password.shared.currentPassword = self.newPasswordTextField.text!
                self.presentIOSAlertWarning(message:"Password changed successfully.") {
                    NotificationCenter.default.post(name: Constant.Notify.updatePassword, object: nil)
                    UserDefaults.standard.set(self.newPasswordTextField.text!, forKey: "MY_OLD_PASS")
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.presentIOSAlertWarning(message: "The passwords entered are not the same!") {}
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        completion?(false)
        dismiss(animated: true, completion: nil)
    }
    
    static func create(completion: ((_ ok:Bool) -> Void)? = nil) -> PasswordViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PasswordViewController") as! PasswordViewController
        vc.completion = completion
        
        return vc
    }
}
