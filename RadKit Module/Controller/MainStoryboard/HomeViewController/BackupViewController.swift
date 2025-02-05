//
//  BackupViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class BackupViewController: UIViewController {

    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var backupSwitch: UISwitch!
    
    var backup: Backup!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.dismissedKeyboardByTouch()
        self.backup = Backup()
        if backupSwitch.isOn {
            self.detailLabel.alpha = 1
        } else {
            self.detailLabel.alpha = 0
        }
    }
    
    @IBAction func backupSwitchValueChanged(_ sender: Any) {
        Password.shared.adminBackupModel = (sender as! UISwitch).isOn
        if (sender as! UISwitch).isOn {
            self.detailLabel.alpha = 1
        } else {
            self.detailLabel.alpha = 0
        }
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        guard !self.nameTextField.text!.isEmpty else {
            self.presentIOSAlertWarning(message: "Please enter a backup name", completion: {})
            return
        }
        self.view.endEditing(true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        self.backup.exportFromDB()
        if Authentication.auth.isLoggedIn {
            let backupName = "\(formatter.string(from: Date()))_" + "\(nameTextField.text!)_bf"
            WebAPI.instance.backup(photo: self.backup.arrayDicts.jsonData, parameter: ["key":"\(Authentication.auth.token)","backup_name":backupName]) { [weak self] (msg) in
                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let msg = msg {
                        self.presentIOSAlertWarning(message: msg) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            self.presentIOSAlertWarning(message: "Please log in to your account") {}
        }

    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
