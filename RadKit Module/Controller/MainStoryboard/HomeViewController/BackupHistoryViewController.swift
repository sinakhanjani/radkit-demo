//
//  BackupHistoryViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class BackupHistoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let shareSegue = "toShareSegue"
    
    var names = [String]()
    var id = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backBarButtonAttribute(color: .white, name: "")
        // Do any additional setup after loading the view.
        self.title = "Available Backup"
        tableView.tableFooterView = UIView()
        fetch()
    }
    
    func fetch() {
        WebAPI.instance.getList(photo: nil, parameter: ["key":"\(Authentication.auth.token)"]) { [weak self] (lists) in
            guard let self = self else { return }
            self.names = lists ?? []

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }                
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.shareSegue {
            let destination = segue.destination as! ShareViewController
            destination.id = id
        }
    }
}
extension BackupHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RadkitTableViewCell
        let item = self.names[indexPath.item].replacingOccurrences(of: "_bf", with: "", options: NSString.CompareOptions.literal, range: nil).replacingOccurrences(of: ".xml", with: "", options: NSString.CompareOptions.literal, range: nil).replacingOccurrences(of: ".json", with: "", options: NSString.CompareOptions.literal, range: nil)

        cell.label_1.text = item.replacingOccurrences(of: "\(String(item.prefix(10)))_", with: "", options: NSString.CompareOptions.literal, range: nil)
        if item.count > 10 {
            cell.label_2.text = String(item.prefix(10))
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        guard let cell = tableView.cellForRow(at: indexPath) as? RadkitTableViewCell else {
//            return nil
//        }
        let returntion = UITableViewRowAction.init(style: .default, title: "Restore") { (action, index) in
            self.presentIOSAlertWarningWithTwoButton(message: "Do you want to restore this backup?", buttonOneTitle: "Yes", buttonTwoTitle: "No") { [weak self] in
                guard let self = self else { return }
                //return
                WebAPI.instance.download(photo: nil, parameter: ["key":"\(Authentication.auth.token)","id":"\(index.item)"]) { [weak self] (data) in
                    guard let self = self else { return }
                    if let data = data {
                        let backup = Backup(dict: data)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            NWSocketConnection.instance.invalidateTimers()
                            NWSocketConnection.instance.dc()
                            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                NWSocketConnection.deviceConnections = []
                                backup.importToDB()
                                Password.shared.adminMode = true
                                self.presentIOSAlertWarning(message:"Backup file restored") { [weak self] in
                                    guard let self = self else { return }
                                    // reluanch apps
                                    if let rootVC = self.storyboard?.instantiateViewController(withIdentifier: "LoaderViewController") as? LoaderViewController {
                                        AppDelegate.reluanchApplication()
                                        UIApplication.set(root: rootVC)
                                    }
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.presentIOSAlertWarning(message:"Backup file is not compatible with current version") {
                                
                            }
                        }
                    }
                }
            } handlerButtonTwo: {
                //
            }
        }
        let shareAction = UITableViewRowAction.init(style: .default, title: "Share") { [weak self] (action, index) in
            guard let self = self else { return }
            self.id = index.item
            self.performSegue(withIdentifier: self.shareSegue, sender: nil)
        }
        let delete = UITableViewRowAction.init(style: .default, title: "Delete") { [weak self] (action, index) in
            guard let self = self else { return }
            self.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this backup?", buttonOneTitle: "Yes", buttonTwoTitle:"No") { [weak self] in
                guard let self = self else { return }
                //remove
                WebAPI.instance.delete(photo: nil, parameter: ["key":"\(Authentication.auth.token)","id":"\(index.item)"]) { [weak self] (msg) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.presentIOSAlertWarning(message: msg ?? "Server connection error") {
                            self.fetch()
                        }
                    }
                }
            } handlerButtonTwo: {
                //
            }
        }
        shareAction.backgroundColor = .systemBlue
        returntion.backgroundColor = UIColor.lightText
        
        var buttons = [delete,returntion]
        if Password.shared.adminMode {
            buttons.insert(shareAction, at: 1)
        }
        return buttons
    }
}
