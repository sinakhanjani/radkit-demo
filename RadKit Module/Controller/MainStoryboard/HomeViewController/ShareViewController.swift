//
//  ShareViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class ShareViewController: UIViewController {

    @IBOutlet weak var mobileTextField: UITextField!
    
    var id: Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.dismissedKeyboardByTouch()
        mobileTextField.keyboardType = .asciiCapableNumberPad
        // Do any additional setup after loading the view.
        print(String(id))
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        if !mobileTextField.text!.isEmpty {
            if mobileTextField.text!.hasPrefix("0") {
                mobileTextField.text!.removeFirst()
            }
        }
        if Authentication.auth.isLoggedIn {
            WebAPI.instance.share(photo: nil, parameter: ["key":"\(Authentication.auth.token)", "id":String(id),"partner":"\(mobileTextField.text!)"]) { (msg) in
                DispatchQueue.main.async {
                    self.presentIOSAlertWarning(message: msg ?? "Server connection error") {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
