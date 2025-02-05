//
//  SettingViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingViewController: UIViewController {
    
    struct Setting {
        let name: String
        let imgName: String
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var registerButton: UIButton!
    
    var settingCellsData = [Setting(name: "Software Password", imgName: "lock"),Setting(name: "Administrator Access", imgName: "lock.shield"), Setting(name: "Receive Notifications", imgName: "message"),Setting(name:"Backup", imgName: "externaldrive.fill"),Setting(name: "Backup Managment", imgName: "internaldrive"),Setting(name:"Help", imgName: "book.closed.fill"),Setting(name: "About Us", imgName: "info.circle"),Setting(name: "Reset Software", imgName: "app")]
    
    var passwordCell: RadkitTableViewCell?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        backBarButtonAttribute(color: .white, name: "")
        if Authentication.auth.isLoggedIn {
            self.registerButton.setTitle(Authentication.auth.mobile, for: .normal)
        } else {
            self.registerButton.setTitle("Login To Account", for: .normal)
        }
        if Authentication.auth.isLoggedIn {
            print(Authentication.auth.token)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(passwordSet), name: Constant.Notify.updatePassword, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Authentication.auth.isLoggedIn {
            self.registerButton.setTitle(Authentication.auth.mobile, for: .normal)
        } else {
            self.registerButton.setTitle("Login To Account", for: .normal)
        }
    }

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toRegisterSegue", sender: nil)
    }
    
    @objc func passwordSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            if !UserDefaults.standard.bool(forKey: "FIRTS_PASSWORD") {
                let pass = "1234"
                Password.shared.currentPassword = pass
                self.presentIOSAlertWarning(message:"Your password is 1234", completion: {})
                UserDefaults.standard.set(true, forKey: "FIRTS_PASSWORD")
                UserDefaults.standard.set(pass, forKey: "MY_OLD_PASS")
            } else {
                if let oldPassword = UserDefaults.standard.value(forKey: "MY_OLD_PASS") as? String {
                    sender.isOn = true
                    Password.shared.currentPassword = oldPassword
                }
            }
        } else {
            self.authenticateWithTouchID { (ok) in
                if ok {
                    Password.shared.currentPassword = nil
                } else {
                    sender.isOn.toggle()
                }
            }
        }
    }
    
    @objc func adminSwitchValueChanged(_ sender: UISwitch) {
        func changeSituation() {
            DispatchQueue.main.async {
                Password.shared.adminMode = sender.isOn
                NotificationCenter.default.post(name: Constant.Notify.adminAccess, object: nil)
            }
        }
        if Password.shared.currentPassword != nil {
            self.authenticateWithTouchID { (ok) in
                if ok {
                    changeSituation()
                } else {
                    sender.isOn.toggle()
                }
            }
        } else {
            changeSituation()
        }
    }
    
    @objc func notificationSwitchValueChanged(_ sender: UISwitch) {
        guard Authentication.auth.isLoggedIn else {
            sender.isOn.toggle()
            self.presentIOSAlertWarning(message:"Please log in to your account", completion: {})
            return
        }
        WebAPI.instance.changeNotificationStatus(status: sender.isOn) { inf in
            DispatchQueue.main.async {
                if let enablePush = inf?.enablePush {
                    sender.isOn = enablePush
                } else {
                    ProgressHUD.showFailed("Please try again!", interaction: false)
                }
            }
        }
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingCellsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
        let item = self.settingCellsData[indexPath.item]
        
        cell.label_1.text = item.name
        cell.imageViewOne.image = UIImage(systemName: item.imgName)
        
        if indexPath.item == 0 {
            cell.passwordSwitch.isOn = Password.shared.currentPassword == nil ? false:true
            cell.passwordSwitch.addTarget(self, action: #selector(self.passwordSwitchValueChanged(_:)), for: .valueChanged)
            cell.passwordSwitch.onTintColor = .RADGreen
            cell.addSubview(cell.passwordSwitch)
            self.passwordCell = cell
        }
        if indexPath.item == 1 {
            let adminSwitch = UISwitch(frame: CGRect(x: UIScreen.main.bounds.width-64, y: 8, width: 60, height: 20))
            adminSwitch.onTintColor = .RADGreen

            adminSwitch.isOn = Password.shared.adminMode
            adminSwitch.addTarget(self, action: #selector(self.adminSwitchValueChanged(_:)), for: .valueChanged)
            cell.addSubview(adminSwitch)
            cell.passwordSwitch.onTintColor = .RADGreen

            if Password.shared.adminBackupModel {
                adminSwitch.isOn = false
                adminSwitch.alpha = 0.4
                adminSwitch.isUserInteractionEnabled = false
            }
        }
        if indexPath.item == 2 {
            let notifSwitch = UISwitch(frame: CGRect(x: UIScreen.main.bounds.width-64, y: 8, width: 60, height: 20))
            notifSwitch.onTintColor = .RADGreen

            notifSwitch.addTarget(self, action: #selector(self.notificationSwitchValueChanged(_:)), for: .valueChanged)
            cell.addSubview(notifSwitch)
            WebAPI.instance.getNotificationStatus { result in
                DispatchQueue.main.async {
                    notifSwitch.isOn = result?.enablePush ?? false
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            let vc = PasswordViewController.create()
            self.present(vc, animated: true, completion: nil)
        }
        if indexPath.item == 1 {
            ////
        }
        if indexPath.item == 3 {
            if Password.shared.adminMode {
                self.performSegue(withIdentifier: "toBackupSegue", sender: nil)
            } else {
                self.presentIOSAlertWarning(message: "Administrator access must be enabled for backup", completion: {})
            }
        }
        if indexPath.item == 4 {
            if Authentication.auth.isLoggedIn {
                self.performSegue(withIdentifier: "toBackupHistory", sender: nil)
            } else {
                self.presentIOSAlertWarning(message: "Please log in to your account", completion: {})
            }
        }
        if indexPath.item == 5 {
            self.performSegue(withIdentifier: "toManualSegue", sender: nil)
        }
        if indexPath.item == 6 {
            self.performSegue(withIdentifier: "toAboutSegue", sender: nil)
        }
        if indexPath.item == 7 {
            presentIOSAlertWarningWithTwoButton(message:"Resetting the software will remove all your data and reload the software. Are you sure you want to do this?", buttonOneTitle: "Yes", buttonTwoTitle: "No") { [weak self] in
                guard let self = self else { return }
                Authentication.auth.logOutAuth()
                UserDefaults.standard.set(false, forKey: "is_begin_in_app")
                Password.shared.adminBackupModel = false
                Password.shared.currentPassword = nil
                Password.shared.adminMode = true
                NWSocketConnection.instance.invalidateTimers()
                NWSocketConnection.instance.dc()
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    NWSocketConnection.deviceConnections = []
                    Backup.cleanAll { status in
                        if status {
                            // reluanch apps
                            if let rootVC = self.storyboard?.instantiateViewController(withIdentifier: "LoaderViewController") as? LoaderViewController {
                                AppDelegate.reluanchApplication()
                                UIApplication.set(root: rootVC)
                            }
                        }
                    }
                }
            } handlerButtonTwo: { }
        }
    }
}

extension SettingViewController {
    @objc func passwordSet() {
        passwordCell!.passwordSwitch.isOn = Password.shared.currentPassword == nil ? false:true
    }
}

// MARK: - NotificationStatus
struct NotificationStatus: Codable {
    let fcmID, customID, packageName: String?
    let enablePush: Bool?
    let id: Int?
    let firstSeen: String?

    enum CodingKeys: String, CodingKey {
        case fcmID = "fcm_id"
        case customID = "custom_id"
        case packageName = "package_name"
        case enablePush = "enable_push"
        case id
        case firstSeen = "first_seen"
    }
}
