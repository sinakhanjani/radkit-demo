//
//  DeviceViewController.swift
//  Master
//
//  Created by Sina khanjani on 6/14/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import UIKit
import Lottie

enum LockType {
    case lock
    case unlock
   case none
}

struct DeviceModel: Hashable {
    var device: Device
    var isLock: LockType = .none
    var connectionState: ConnectionState = .none
}

extension DeviceViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- DEVICE")
        if tag == 501 {
            self.updateCell(bytes, device)
        }
        if tag == 502 {
            self.updateCell(bytes, device)
        }
        if tag == 504 {
            if var bytes = bytes, let device = device {
                print("504", bytes)
                if let fByte = bytes.first, fByte == UInt8(12) {
                    bytes.removeFirst() // del header 12
                    let ip = "\(bytes[0]).\(bytes[1]).\(bytes[2]).\(bytes[3])"
                    print("final ip", ip)
                    _ = CoreDataStack.shared.updateIPInDatabaseModules(serial: Int(device.serial), ip: ip)
                    DispatchQueue.main.async { [weak self] in
                        self?.presentIOSAlertWarning(message: "The local network ip has been updated", completion: { [weak self] in
                            self?.reluanchConnection()
                        })
                    }
                }
            }
        }
        if tag == 1111 {
            self.updateCell(bytes, device)
        }
    }
}

class DeviceViewController: UIViewController, EspTouchViewControllerDelegate, ConfigAdminRolles {
    enum Section {
        case main
    }
    
    func adminChanged() {
        admin()
    }
    
    func completeEspTouchResults() {
        sendBroadcast1()
    }

    @IBOutlet weak var tableView: UITableView!
    
    private let senarioConnection = SenarioConnection()
    
    let refreshControl = UIRefreshControl()
    var devicesModel = [DeviceModel]()
    var timer: Timer?

    private var dataSource: UITableViewDiffableDataSource<Section, DeviceModel>!
    private var snapshot = NSDiffableDataSourceSnapshot<Section, DeviceModel>()
    
    var resetDeviceAdded = false
    
    var deviceAdded = false {
        willSet {
            if (newValue == true) && (resetDeviceAdded == false) {
                resetDeviceAdded = true
                DispatchQueue.main.asyncAfter(deadline: .now()+1.6) { [weak self] in
                    CoreDataStack.shared.saveContext()
                    CoreDataStack.shared.fetchDatabase()
                    self?.reluanchConnection()
                    self?.resetDeviceAdded = false
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        adminAccess()
        startLaunchTable()
        setTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
        // this is for check new device added to DB and connect it to wifi
        sendBroadcast1()
    }

    private func sendBroadcast1() {
        deviceAdded = false
        if WebAPI.instance.reachability.connection == .wifi {
            UDPBroadcast.instance.UDPBroadcast1(addModule: true) { [weak self] status, device in
                if status == .deviceAdded {
                    guard let self = self else { return }
                    self.deviceAdded = true
                }
            }
        }
    }

    private func reloadSnapshot(animated: Bool = false) {
        snapshot = createSnapshot()
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    private func updateOnly(device: Device) {
        // HOT:
        NWSocketConnection.instance.send(tag:501, device: device, typeRequest: .stateRequest, parameterRequest: .deviceParameter, results: nil)
    }
    
    private func updateAllCells() {
        devicesModel.forEach { item in
            if !item.device.isBossDevice {
                updateOnly(device: item.device)
            }
        }
    }
    
    private func configureDataSource() {
        dataSource = .init(tableView: tableView, cellProvider: { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath) as! RadkitTableViewCell
            let connectionState = item.device.connectionState

            cell.indicator.color = .label
            cell.indicator.alpha = 1.0
            cell.indicator.startAnimating()
                        
            switch connectionState {
            case .wifi:
                cell.imageViewThree.image = UIImage(systemName: "wifi")
            case .ipStatic:
                cell.imageViewThree.image = UIImage(systemName: "wifi.circle.fill")
            case .mqtt:
                cell.imageViewThree.image = UIImage(systemName: "cloud")
            case .none:
                cell.indicator.stopAnimating()
                cell.indicator.alpha = 0.0
                cell.imageViewThree.image = UIImage(systemName: "antenna.radiowaves.left.and.right.slash")
            }
            
            switch connectionState {
            case .none:
                break
            default:
                cell.indicator.alpha = 0
                cell.indicator.stopAnimating()
            }
            
            if Int(item.device.type) < 10 {
                cell.imageViewOne.image = UIImage.init(named: "0\(Int(item.device.type))")!
            } else {
                cell.imageViewOne.image = UIImage.init(named: "\(Int(item.device.type))")!
            }

            if let deviceTypeName = DeviceType.init(rawValue: Int(item.device.type))?.changed() {
                if item.device.isBossDevice {
                    var serial = "\(item.device.serial)"
                    if serial.count < 6 {
                        while serial.count < 6 {
                            serial = "0" + serial
                        }
                    }
                    cell.label_1.text = deviceTypeName + "\(serial)"
                } else {
                    cell.label_1.text = deviceTypeName + "\(item.device.serial)"
                }
                if !item.device.isBossDevice {
                    cell.label_2.text = item.device.isStatic ? item.device.staticIP:item.device.ip
                } else {
                    cell.label_2.text = "Gateway-\(item.device.bridgeDeviceSerial)"
                }
            }

            let isLock = (item.device.isLock)
            let isLockImg = UIImage(systemName: "lock")
            let isUnlockImg = UIImage(systemName: "lock.open")
            cell.imageViewTwo.image = isLock ? isLockImg:isUnlockImg
            
            // change all image only for boss devices
            if item.device.isBossDevice {
                cell.imageViewTwo.image = nil//UIImage(systemName: "lock")
                cell.imageViewThree.image = UIImage.init(named: "bus")! //UIImage(systemName: "wifi")
            }
            
            return cell
        })
    }
    
    private func createSnapshot() -> NSDiffableDataSourceSnapshot<Section,DeviceModel> {
        var snapshot = NSDiffableDataSourceSnapshot<Section,DeviceModel>()

        snapshot.appendSections([.main])
        snapshot.appendItems(devicesModel, toSection: .main)
        
        return snapshot
    }
    
    private func setTimer() {
        // timer refresh data
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            let devicesModel = NWSocketConnection.deviceConnections.map { DeviceModel(device: $0.tcp.device, isLock: $0.tcp.device.isLock ? .lock:.unlock, connectionState: $0.tcp.device.connectionState) }.uniqued()
            var bossesDeviceModel = [DeviceModel]()
            if let dbBossDevices = CoreDataStack.shared.devices?.filter({ $0.isBossDevice == true }) {
                bossesDeviceModel = dbBossDevices.map { DeviceModel(device: $0, isLock: .unlock, connectionState: .wifi) }.uniqued()
            }

            self.devicesModel = devicesModel + bossesDeviceModel
            self.snapshot = self.createSnapshot()
            self.dataSource.apply(self.snapshot, animatingDifferences: false)
        })
    }
    
    @objc func reluanchConnection() {
        timer?.invalidate()
        timer = nil
        devicesModel.removeAll()
        AppDelegate.reluanchApplication() // it make 2 second
        DispatchQueue.main.asyncAfter(deadline: .now()+0) { [weak self] in //FIX 3second
            guard let self = self else { return }
            self.startLaunchTable()
            DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
                self?.setTimer()
            }
        }
        
        refreshControl.endRefreshing()
    }

    @objc private func changedStateConnection() {
        //
    }
    
    func startLaunchTable() {
        if let dbDevices = CoreDataStack.shared.devices {
            devicesModel = dbDevices.map { DeviceModel(device: $0) }
            reloadSnapshot()
            updateAllCells()
        }
    }
    
    func updateUI() {
        configureDataSource()
        if CoreDataStack.shared.devices?.isEmpty == true || CoreDataStack.shared.devices == nil {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.2) { [weak self] in
                guard let self = self else { return }
                self.performSegue(withIdentifier: "toEspTouchViewControllerSegue", sender: nil)
            }
        }
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.black,NSAttributedString.Key.font:UIFont.persianFont(size: 10)]
        
        refreshControl.attributedTitle = NSAttributedString(string: "Updating", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(reluanchConnection), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = .RADGreen
        tableView.refreshControl = refreshControl
    }
    
    func updateCell(_ results: [UInt8]?,_ device: Device?) -> Void {
        let isLock = (results?[1] == UInt8(1))
        let isLockImg = UIImage(systemName: "lock")
        let isUnlockImg = UIImage(systemName: "lock.open")
        device?.isLock = isLock
        DispatchQueue.main.async {
            CoreDataStack.shared.saveContext()
        }
        if let index = self.devicesModel.lastIndex(where: { $0.device.serial == device?.serial }) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let cell = self.tableView.cellForRow(at: IndexPath(item: index, section: 0)) as? RadkitTableViewCell {
                    if let connectionState = device?.connectionState {
                        switch connectionState {
                        case .wifi:
                            cell.imageViewThree.image = UIImage(systemName: "wifi")
                        case .ipStatic:
                            cell.imageViewThree.image = UIImage(systemName: "wifi.circle.fill")
                        case .mqtt:
                            cell.imageViewThree.image = UIImage(systemName: "cloud")
                        case .none:
                            cell.imageViewThree.image = UIImage(systemName: "antenna.radiowaves.left.and.right.slash")
                        }
                    }
                    
                    cell.indicator.alpha = 0.0
                    cell.imageViewTwo.image = isLock ? isLockImg:isUnlockImg
                    cell.indicator.stopAnimating()
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EspTouchViewController {
            destination.delegate = self
        }
    }
}

extension DeviceViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let cell = tableView.cellForRow(at: indexPath) as? RadkitTableViewCell else { return nil }
        guard let items = CoreDataStack.shared.devices else { return nil }

        let deleteAction = UITableViewRowAction.init(style: .default, title: "Delete") { [weak self] (action, index) in
            self?.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete the device?", buttonOneTitle: "Yes", buttonTwoTitle: "No", handlerButtonOne: { [weak self] in
                if let removedDevice = self?.devicesModel[indexPath.item].device {
                    CoreDataStack.shared.deleteRadkitModule(device: removedDevice)
                    self?.devicesModel.remove(at: indexPath.item)
                }
                self?.reloadSnapshot(animated: true)
            }, handlerButtonTwo: {})
        }
        
        let situationAction = UITableViewRowAction.init(style: .default, title: "") { [weak self] (action, index) in
            guard let self = self else { return }
            let model = self.devicesModel[indexPath.item]
            var lockType: LockRequest = .lock
            switch model.device.isLock {
            case true:
                lockType = .open
            case false:
                lockType = .lock
            }
                        
            NWSocketConnection.instance.send(tag:502,device: model.device, typeRequest: .lockRequest, lockRequest: lockType, results: nil)
            DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
                guard let self = self else { return }
                self.devicesModel[indexPath.item].isLock = (lockType == .lock) ? .lock:.unlock
                self.reloadSnapshot()
                self.updateOnly(device: model.device)
            }
        }
        
        let settingAction = UITableViewRowAction.init(style: .default, title: "Setting") { [weak self] (action, index) in
            guard let self = self else { return }
            let alertController = UIAlertController(title: "Config", message: "", preferredStyle: .actionSheet)
            
            let bridgeBoss = UIAlertAction(title: "Select Gateway", style: UIAlertAction.Style.default, handler: { [weak self] alert -> Void in
                guard let self = self else { return }
                let iDevice = self.snapshot.itemIdentifiers[indexPath.item].device
                let vc = SelectBridgeDeviceViewController.create(completion: { [weak self] device in
                    guard let self = self else { return }
                    if let device = device {
                        CoreDataStack.shared.updateBridgeDeviceSerial(serial: device.serial, device: iDevice)
                        if let dbDevices = CoreDataStack.shared.devices {
                            self.devicesModel = dbDevices.map { DeviceModel(device: $0) }
                            self.reloadSnapshot()
                        }
                    }
                })
                vc.selectedDevice = CoreDataStack.shared.devices?.first(where: { device in
                    device.serial == iDevice.bridgeDeviceSerial
                })
                self.present(vc, animated: true)
            })
            
            let inputs = UIAlertAction(title: "Input Setting", style: UIAlertAction.Style.default, handler: { [weak self] alert -> Void in
                guard let self = self else { return }
                if let devices = CoreDataStack.shared.devices {
                    let device = self.snapshot.itemIdentifiers[indexPath.item].device//devices[indexPath.item]
                    guard Int(device.version) >= 2 && (device.type == Int(8) || device.type == Int(10)) || device.type == Int(12) else { return }
                    let vc = InputViewController.create()
                    vc.delegate = self
                    vc.device = device
                    self.present(vc, animated: true, completion: nil)
                }
            })
            let notifStatus = UIAlertAction(title: "Notifications", style: UIAlertAction.Style.default, handler: { [weak self] alert -> Void in
                guard let self = self else { return }
                if let devices = CoreDataStack.shared.devices {
                    let device = self.snapshot.itemIdentifiers[indexPath.item].device//devices[indexPath.item]
                    guard (device.type == Int(3) || device.type == Int(10)) || device.type == Int(12) else { return }
                    guard Authentication.auth.isLoggedIn else {
                        self.presentIOSAlertWarning(message: "Please log in to your account", completion: {})
                        return
                    }
                    let vc = NotifyTableViewController.create(device: device)
                    self.present(vc, animated: true, completion: nil)
                }
            })
            let networkAction = UIAlertAction(title: "Network", style: UIAlertAction.Style.default, handler: { [weak self] alert -> Void in
                guard let self = self else { return }
                let vc = StaticIpViewController.create(completion: { [weak self] (ok) in
                    guard let self = self else { return }
                    if ok {
                        self.reluanchConnection()
                    }
                })
                vc.device = self.snapshot.itemIdentifiers[indexPath.item].device//CoreDataStack.shared.devices?[indexPath.item]
                self.present(vc, animated: true)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {
                (action : UIAlertAction!) -> Void in })
            
            cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
            
            if let devices = CoreDataStack.shared.devices {
                let device = self.snapshot.itemIdentifiers[indexPath.item].device//devices[indexPath.item]
                if Int(device.version) >= 2 && (device.type == Int(8) || device.type == Int(10)) || device.type == Int(12) {
                    inputs.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(inputs)
                }
                if ((device.type == Int(3) || device.type == Int(10)) || device.type == Int(12)) && !device.isBossDevice {
                    notifStatus.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(notifStatus)
                }
                let internalSenarioRemotes03 = UIAlertAction.init(title: "Event Scenario Setting", style: .default) {[weak self] (action) in
                    guard let self = self else { return }
                    let vc = TimeViewController.create(lastTime: nil, type: .channel, completion: { [weak self] (number) in
                        guard let self = self else { return }
                        guard let number = number else { return }
                        self.senarioConnection.sendSenarioToDeviceRemote03(viewController: self, device: device, channel: Int(number))
                    })
                    vc.channels = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
                    self.present(vc, animated: true, completion: nil)
                }
                let timeZone = UIAlertAction.init(title: "Update Time", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    let vc = TimeZoneViewController.create(device: device)
                    self.present(vc, animated: true)
                }
                let connectToLocal = UIAlertAction.init(title: "Connect to Local Network", style: .default) { [weak self] (action) in
                    guard let self = self else { return }
                    let vc = ConnectToWifiViewController.create(device: device)
                    self.present(vc, animated: true)
                }
                let updateLocalIP = UIAlertAction.init(title: "Update Local IP Address", style: .default) { [weak self] (action) in
                    NWSocketConnection.instance.send(tag:504,device: device, typeRequest: .updateDeviceInfo, data: [UInt8(0)], results: nil)
                }
                if let deviceType = DeviceType(rawValue: Int(device.type)) {
                    switch deviceType {
                    case .remotes:
                        if !device.isBossDevice {
                            internalSenarioRemotes03.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                            alertController.addAction(internalSenarioRemotes03)
                        }
                    default:
                        break
                    }
                    
                    if deviceType != .switch12_sim_0 && !device.isBossDevice {
                        networkAction.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                        alertController.addAction(networkAction)
                    }
                }
                if self.snapshot.itemIdentifiers[indexPath.item].device.isBossDevice {
                    bridgeBoss.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(bridgeBoss)
                } else {
                    timeZone.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(timeZone)
                    if self.snapshot.itemIdentifiers[indexPath.item].connectionState == .wifi && self.snapshot.itemIdentifiers[indexPath.item].device.ip == "192.168.4.1" {
                        connectToLocal.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                        alertController.addAction(connectToLocal)
                    }
                    if self.snapshot.itemIdentifiers[indexPath.item].connectionState == .mqtt && self.snapshot.itemIdentifiers[indexPath.item].device.ip == "192.168.4.1" {
                        updateLocalIP.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                        alertController.addAction(updateLocalIP)
                    }
                }
            }
            
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
        settingAction.backgroundColor = .lightGray
        let situationTitle = (devicesModel[indexPath.item].device.isLock == true) ? "Unlock":"Lock"
        let situationColor = UIColor.darkGray
        
        situationAction.backgroundColor = situationColor
        situationAction.title = situationTitle
        
        if Password.shared.adminMode {
            var sides = [deleteAction,settingAction]
            if !devicesModel[indexPath.item].device.isBossDevice {
                sides.insert(situationAction, at: 1)
            }
            return sides
        } else {
            return nil
        }
    }
}

extension DeviceViewController: InputStatusViewControllerDelegate {
    func inputStatusVCDismiised() {
        NWSocketConnection.instance.delegate = self
    }
}

//if let _ = currentRunLoop {
//    outputStream?.remove(from: currentRunLoop!, forMode: RunLoop.Mode.default)
//}

// 1.NEW DEVICE ADDED FIRST TIME APP OPEN
// 2.RELOAD WHEN COME BACK TO THIS VIEWCONTROLLER
