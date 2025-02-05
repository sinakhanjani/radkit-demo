//
//  RegisterViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var deleteAccountButton: RoundedButton!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!

    var isRegisterWithPhone: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        codeTextField.keyboardType = .asciiCapableNumberPad
        self.view.dismissedKeyboardByTouch()
        self.title = "Login To Account"
        if Authentication.auth.isLoggedIn {
            self.deleteAccountButton.alpha = 1
        } else {
            self.deleteAccountButton.alpha = 0
        }
    }
    
    
    @IBAction func deleteAccountButtonTapped(_ sender: Any) {
        self.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this account?\nYour profile and all information will be deleted", buttonOneTitle: "Yes", buttonTwoTitle:"No") { [weak self] in
            guard let self = self else { return }
            //remove
            WebAPI.instance.delete(photo: nil, parameter: ["key":"\(Authentication.auth.token)","id":"-1"]) { [weak self] (msg) in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    Authentication.auth.logOutAuth()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        } handlerButtonTwo: {
            //
        }
    }
    
    @IBAction func sendCodeButtonTapped(_ sender: UIButton) {
        if mobileTextField.text!.isValidEmail {
            registerWithEmail()
            return
        }
        if let no = mobileTextField.text, no.count >= 10, let _ = Int(no) {
            registerWithMobile()
            return
        }
        
        presentIOSAlertWarning(message: "Please enter a valid email", completion: {})
    }
    
    func registerWithEmail() {
        let vc = IndicatorViewController.create(completion: nil)

        view.endEditing(true)
        present(vc, animated: false)
        WebAPI.instance.sendEmail(photo: nil, parameter: ["name":"","email":mobileTextField.text!]) { (msg) in
            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
                    vc.dismiss(animated: false) {
                        self.isRegisterWithPhone = false
                        if let msg = msg {
                            self.presentIOSAlertWarning(message: msg) {}
                        }
                    }
                }
            }
        }
    }
    
    func registerWithMobile() {
        let vc = IndicatorViewController.create(completion: nil)

        if !mobileTextField.text!.isEmpty && mobileTextField.text!.hasPrefix("0") {
            mobileTextField.text!.removeFirst()
        }
        view.endEditing(true)
        present(vc, animated: false)
        WebAPI.instance.sendSMS(photo: nil, parameter: ["name":"","email":"","mobile":"\(mobileTextField.text!)"]) { (msg) in
            DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
                vc.dismiss(animated: false, completion: nil)
                self.isRegisterWithPhone = true
                if let msg = msg {
                    self.presentIOSAlertWarning(message: msg) {}
                }
            }
        }
    }
    
    @IBAction func VerifyCodeButtonTapped(_ sender: UIButton) {
        let vc = IndicatorViewController.create(completion: nil)
        present(vc, animated: true, completion: nil)
        WebAPI.instance.verifySMS(photo: nil, parameter: ["otp":"\(codeTextField.text!)"]) { (data) in
            DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
                vc.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    if let data = data {
                        if data.error {
                            DispatchQueue.main.async {
                                self.presentIOSAlertWarning(message: data.message) {}
                            }
                        } else {
                            DispatchQueue.main.async {
                                var name = ""
                                if self.isRegisterWithPhone {
                                    name = data.profile.mobile ?? ""
                                } else {
                                    name = data.profile.email ?? ""
                                }
                                Authentication.auth.authenticationUser(token: data.profile.apikey, isLoggedIn: true, mobile: name)
                                self.presentIOSAlertWarning(message: data.message) {
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.presentIOSAlertWarning(message: "Something happend wrong!") { }
                        }
                    }
                }
            }
        }
    }
}
