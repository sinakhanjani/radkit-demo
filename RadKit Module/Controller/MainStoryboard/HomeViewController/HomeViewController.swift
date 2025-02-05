//
//  HomeViewController.swift
//  Master
//
//  Created by Sina khanjani on 6/15/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import UIKit
import CoreLocation
import ProgressHUD

class HomeViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,AddEquipmentViewControllerDelegate,RadKitCollectionViewCellDelegate, NWSocketConnectionDelegate {
    var allDevicesScenarioItems = [String]()
    var count = 0

    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
//        print("HOME - TAG \(tag), \(device?.serial) \(bytes)")
        
        guard let bytes = bytes, let device = device, bytes.count >= 2, let fByte = bytes.first else { return }
        if fByte == UInt8(8) && bytes.count == 2 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if bytes[0] == UInt8(8) && bytes[1] == UInt8(0) {
                    var serial = "\(device.serial)"
                    if serial.count < 6 {
                        while serial.count < 6 {
                            serial = "0" + serial
                        }
                    }

                    self.allDevicesScenarioItems.append("\(serial)")
                    NotificationCenter.default.post(name: Notification.Name("ReceievdSenarioSuccess"), object: nil)
                    if self.count == self.allDevicesScenarioItems.count {
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.addedScenarioAllDeviceMsg), object: nil)
                        self.addedScenarioAllDeviceMsg()
                    }
                }
            }
        }
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadKitCollectionViewCell) {
        guard Password.shared.adminMode else {
            return
        }
        if let indexPath = self.bottomCollectionView.indexPath(for: cell) {
            if let rooms = self.rooms {
                if let index = self.selectedIndex {
                    if let equimpents = CoreDataStack.shared.fetchEquipmentIn(theRoom: rooms[index]) {
                        let equipment = equimpents[indexPath.item]
                        let message = equipment.isShortcut ? "Do you want to delete this scenario shortcut?\nBy removing this shortcut, the main scenario will remain":"Do you want to delete this module?"
                        let tt = equipment.isShortcut ? "Remove Scenario Shortcut":"Appliance Removal"
                        let title = NSAttributedString(string: tt, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 17.0)!, NSAttributedString.Key.foregroundColor : UIColor.label])
                        let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.label])

                        let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
                        alertController.setValue(attributeMsg, forKey: "attributedMessage")
                        alertController.setValue(title, forKey: "attributedTitle")
                        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                            //
                        }
                        let remove = UIAlertAction.init(title: equipment.isShortcut ? "Delete Scenario Shortcut":"Delete Module", style: .default) { [weak self] (action) in
                            guard let self = self else { return }
                            CoreDataStack.shared.deleteEquipmentInDatabase(equipment: equipment)
                            self.bottomCollectionView.reloadData()
                        }
                        remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")

                        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")

                        alertController.addAction(cancelAction)
                        alertController.addAction(remove)
                        
                        self.present(alertController, animated: true, completion: nil)
                        
                        return
                    }
                }
            }
        }
    }
    
    // PROTOCOL
    func addEquipmentButtonTapped(deviceType:DeviceType) {
        self.presentAlertActionWithTextField(message: "", title: "Add Appliance", textFieldPlaceHolder: "Enter device name") { [weak self] name in
            guard let self = self else { return }
            if let rooms = self.rooms {
                if let index = self.selectedIndex {
                    let img = UIImage.init(named: deviceType.imagename())!.pngData()!
                    let _ = CoreDataStack.shared.addEquipment(addToRoom: rooms[index], image: img, name: name, type: Int64(deviceType.rawValue), isShortcut: false, senarioId: 0)
                    self.bottomCollectionView.reloadData()
                }
            }
        }
    }

    @IBOutlet weak var rightBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var bottomCollectionView: UICollectionView!
    @IBOutlet weak var bannerCollectionView: UICollectionView!
    @IBOutlet weak var warningTitleLabel: UILabel!
    @IBOutlet weak var warningView: UIView!
    
    private let senarioConnection = SenarioConnection()

    var rooms: [Room]?
    let imagePicker = UIImagePickerController()
    var selectedEquipment: Equipment?
    var selectedIndex: Int? {
        willSet {
            print("Last selected Index", newValue)
            if let newValue = newValue {
                if let selectedIndex = selectedIndex {
                    if newValue != selectedIndex {
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in
                            self?.bottomCollectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        backBarButtonAttribute(color: .white, name: "")
        bottomCollectionView.tag = 1
        if let rooms = CoreDataStack.shared.fetchRoomsInDatabase() {
            self.rooms = rooms
            if !rooms.isEmpty {
                selectedIndex = 0
            }
        }
        updateUI()
        imagePicker.delegate = self
        
        let cellCize: CGSize = CGSize(width: UIScreen.main.bounds.width-64, height: bannerCollectionView.bounds.height)
        bannerCollectionView.collectionViewLayout = CoAnimationCollectionViewFlowLayout(itemSize: cellCize);
        bannerCollectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        
        if let selectedIndex = self.selectedIndex {
            bannerCollectionView.scrollToItem(at: IndexPath.init(item: selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    
        // add observer
        self.warningView.alpha = 0.0
        NotificationCenter.default.addObserver(self, selector: #selector(someApplianceAdded), name: Notification.Name("someApplianceAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endSenario), name: Constant.Notify.endSenario, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }
    
    @objc func someApplianceAdded() {
        bottomCollectionView.reloadData()
    }
    
    @objc func endSenario() {
        self.warningView.alpha = 0.0
    }
    
    func updateUI() {
        NotificationCenter.default.addObserver(self, selector: #selector(adminModeTapped), name: Constant.Notify.adminAccess, object: nil)
        adminMode()
        if let devices = CoreDataStack.shared.devices {
            if devices.isEmpty {
                self.tabBarController?.selectedIndex = 2
            }
        } else {
            self.tabBarController?.selectedIndex = 2
        }
    }
    
    func adminMode() {
        if !Password.shared.adminMode {
            self.rightBarButtonItem.isEnabled = false
        } else {
            self.rightBarButtonItem.isEnabled = true
        }
    }
    
    @objc func adminModeTapped() {
        adminMode()
    }
    
    @IBAction func rightBarButtonTapped(_ sender: Any) {
        let message = ""
        let alertController = UIAlertController(title: "Add and Edit Your Appliance Or Rooms", message: message, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
            //
        }
        let addRoom = UIAlertAction.init(title: "Add Room", style: .default) { (action) in
            self.presentAlertActionWithTextField(message: "", title: "Add Room", textFieldPlaceHolder: "Enter room name") { [weak self] name in
                guard let self = self else {return }
                let _ = CoreDataStack.shared.addRoomInDatabase(roomImage: nil, roomName: name)
                if let lastRooms = CoreDataStack.shared.fetchRoomsInDatabase() {
                    self.rooms = lastRooms
                    self.bannerCollectionView.reloadData()
                    self.bottomCollectionView.reloadData()
                    DispatchQueue.main.asyncAfter(deadline: .now()+0) {
                        self.bannerCollectionView.scrollToItem(at: IndexPath.init(item: lastRooms.count-1, section: 0), at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
        let removeRoom = UIAlertAction.init(title: "Delete Room", style: .default) { (action) in
            self.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete the room?", buttonOneTitle: "Yes", buttonTwoTitle: "No", handlerButtonOne: { [weak self] in
                guard let self = self else {return }
                if let index = self.selectedIndex, let rooms = self.rooms {
                    CoreDataStack.shared.removeRoomInDatabase(room: rooms[index])
                    if let lastRooms = CoreDataStack.shared.fetchRoomsInDatabase() {
                        self.rooms = lastRooms
                        self.bannerCollectionView.reloadData()
                        if index > 0 {
                            self.selectedIndex = index-1
                            self.bannerCollectionView.scrollToItem(at: IndexPath.init(item: index-1, section: 0), at: .centeredHorizontally, animated: true)
                        } else {
                            self.selectedIndex = 0
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.3) { [weak self] in
                                self?.bottomCollectionView.reloadData()
                            }
                        }
                    }
                }
            }) { }
        }
        let AddEquipment = UIAlertAction.init(title: "Add Appliance", style: .default) { [weak self] (action) in
            guard let self = self else {return }
            self.performSegue(withIdentifier: "toAddEquipmentSegue", sender: nil)
        }
        let addImageToRoom = UIAlertAction.init(title: "Edit Background", style: .default) { [weak self] (action) in
            guard let self = self else { return }
            if let _ = self.selectedIndex {
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        addRoom.setValue(UIColor.RADGreen, forKey: "titleTextColor")
        removeRoom.setValue(UIColor.RADGreen, forKey: "titleTextColor")
        AddEquipment.setValue(UIColor.RADGreen, forKey: "titleTextColor")
        addImageToRoom.setValue(UIColor.RADGreen, forKey: "titleTextColor")

        alertController.addAction(cancelAction)
        alertController.addAction(addRoom)
        alertController.addAction(removeRoom)
        alertController.addAction(AddEquipment)
        alertController.addAction(addImageToRoom)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            if let index = self.selectedIndex {
                if let cell = self.bannerCollectionView.cellForItem(at: IndexPath.init(row: index, section: 0)) as? RadKitCollectionViewCell {
                    cell.imageView1.image = image
                    // update image database.
                    if let rooms = CoreDataStack.shared.fetchRoomsInDatabase() {
                        self.rooms = rooms
                        CoreDataStack.shared.updateImageForRoom_2(inRoom: rooms[index], image: image.jpegData(compressionQuality: 0.3)!)
                    }
                }
            }
        }
    }
    
    @objc private func addedScenarioAllDeviceMsg() {
        if !self.allDevicesScenarioItems.isEmpty {
            let serials = self.allDevicesScenarioItems.joined(separator: ", ")
            var msg = ""
            
            if self.count == self.allDevicesScenarioItems.count {
                msg = "All devices received the scenario"
            } else {
                msg = "Device \(serials) received the scenario"
            }
            
            ProgressHUD.showSucceed(msg, interaction: false)

            self.allDevicesScenarioItems = []
            self.count = 0
        } else {
            self.count = 0
            let msg = "scenario not received, Please try again"
            ProgressHUD.showFailed(msg, interaction: false)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AddEquipmentViewController {
            destination.delegate = self
        }
        if let destination = segue.destination as? SwitchViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? RGBViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? DimmerViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? ThermostatViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? TvRemoteViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? CustomRemoteViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? WifiRemoteViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? SwitchSenarioViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? ACViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? HumViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? EngineViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? InputStatusViewController {
            destination.equipment = self.selectedEquipment
        }
        if let destination = segue.destination as? CCTVViewController {
            destination.equipment = self.selectedEquipment
        }
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            if collectionView.tag == 0 {
                let xPoint = scrollView.contentOffset.x + scrollView.frame.width / 2
                let yPoint = scrollView.frame.height / 2
                let center = CGPoint(x: xPoint, y: yPoint)
                if let ip = bannerCollectionView.indexPathForItem(at: center) {
                    if ip.item != self.selectedIndex {
                        self.selectedIndex = ip.item
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            if let _ = self.selectedIndex {
                if let items = self.rooms {
                    if items.isEmpty {
                        return 0
                    }
                    return items.count
                }
            }
            return 0
        } else {
            if let index = self.selectedIndex {
                return self.rooms?[index].equipments?.count ?? 0
            }
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bannerCell", for: indexPath) as! RadKitCollectionViewCell
            if let rooms = self.rooms {
                let item = rooms[indexPath.item]
                
                if let imageData = item.image {
                    cell.imageView1.image = UIImage(data: imageData)
                } else {
                    cell.imageView1.image = nil
                    if indexPath.item % 2 == 0 {
                        cell.imageView1.backgroundColor = .darkGray
                    } else {
                        cell.imageView1.backgroundColor = .darkGray
                    }
                }
                cell.pageControl.numberOfPages = rooms.count
                cell.label1.text = item.name
                cell.pageControl.currentPage = indexPath.item
            }
            print("cellForItemAt,", indexPath.item)

            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "centerMainCollectionView", for: indexPath) as! RadKitCollectionViewCell
            cell.delegate = self
            if let rooms = self.rooms {
                if let index = self.selectedIndex {
                    if let equipments = CoreDataStack.shared.fetchEquipmentIn(theRoom: rooms[index]) {
                        let equipment = equipments[indexPath.item]
                        if equipment.isShortcut {
                            let senariosX = CoreDataStack.shared.fetchSenarios()
                            if let senario = senariosX.first(where: { sn in
                                sn.id == equipment.senarioId
                            }) {
                                SenarioSendDataV2Controller.run(viewController: self, senario) { dict in
                                    if dict != nil {
                                        cell.imageView2.image = UIImage(named: "new_sc")
                                    } else {
                                        cell.imageView2.image = UIImage(named: "old_sc")
                                    }
                                }
                            }
                            cell.roundedView1.backgroundColor = .secondarySystemGroupedBackground
                        } else {
                            cell.imageView2.alpha = 0
                            cell.roundedView1.backgroundColor = .secondarySystemGroupedBackground
                        }
                        if let data = equipments[indexPath.item].image {
                            cell.imageView1.image = UIImage.init(data: data)
                        }
                        
                        cell.label1.text = equipments[indexPath.item].name
                    }
                }
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.tag == 0 {
            return CGSize.init(width: collectionView.frame.width-64, height: collectionView.frame.height-16)

        } else {
            var numberOfColumns: CGFloat = 2
            if UIScreen.main.bounds.width > 320 {
                numberOfColumns = 3
            }
            let spaceBetweenCells: CGFloat = 10
            let padding: CGFloat = 40
            let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns

            return CGSize.init(width: cellDimention, height: 140.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("didEndDisplaying,", indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView.tag == 0 {
            return 0
        } else {
            return 10
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 0 {
            //
        } else {
            if let rooms = self.rooms {
                if let index = self.selectedIndex {
                    if let equipments = CoreDataStack.shared.fetchEquipmentIn(theRoom: rooms[index]) {
                        let equipment = equipments[indexPath.item]
                        if equipment.isShortcut {
                            let senariosX = CoreDataStack.shared.fetchSenarios()
                            if let senario = senariosX.first(where: { sn in
                                sn.id == equipment.senarioId
                            }) {
                                // new or old?
                                SenarioSendDataV2Controller.run(viewController: self, senario) {[weak self] dict in
                                    guard let self = self else { return }
                                    if let dict = dict {
                                        for (key,value) in dict {
                                            if let device = CoreDataStack.shared.devices?.first(where: { d in
                                                d.serial == key
                                            }) {
                                                // data
                                                var data = value
                                                // add tedad ejra if needed
                                                let reapetedTime = senario.repeatedTime
                                                if reapetedTime != 0 {
                                                    data.append(UInt8(reapetedTime))
                                                }
                                                // send
                                                print("NEW SENARIO SEND",device.serial, data)
                                                NWSocketConnection.instance.send(tag: 48, device: device, typeRequest: .scenarioRequest,data: data, results: nil)
                                            }
                                        }
                                        if !dict.isEmpty {
                                            ProgressHUD.show(nil, interaction: false)
                                            self.perform(#selector(self.addedScenarioAllDeviceMsg), with: nil, afterDelay: 2)
                                        }
                                    } else {
                                        self.senarioConnection.runSenario(viewController: self, senario: senario) { [weak self] (senarioRunType) in
                                            guard let self = self else { return }
                                            switch senarioRunType {
                                            case .begin:
                                                self.warningView.alpha = 0.74
                                                self.warningTitleLabel.text = "Command 1 sent"
                                                print(".begin senario")
                                                break
                                            case .last:
                                                self.warningTitleLabel.text = "Last command sent"
                                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.2) { [weak self] in
                                                    guard let self = self else { return }
                                                    self.warningView.alpha = 0.0
                                                }
                                                print(".last senario")
                                                break
                                            case .enter(let index):
                                                self.warningTitleLabel.text = "Command \(index + 1) sent"
                                                print(".enter \(index) senario")
                                                break
                                            case .failed:
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if let deviceType = DeviceType.init(rawValue: Int(equipment.type)) {
                                self.selectedEquipment = equipment
                                switch deviceType {
                                case .switch6:
                                    self.performSegue(withIdentifier: "toSwitchVCSegue", sender: nil)
                                case .rgbController:
                                    self.performSegue(withIdentifier: "toRGBVCSegue", sender: nil)
                                case .dimmer:
                                    self.performSegue(withIdentifier: "toDimmerSegue", sender: nil)
                                case .thermostat:
                                    self.performSegue(withIdentifier: "toThermoSegue", sender: nil)
                                case .humidityControl:
                                    self.performSegue(withIdentifier: "toHumSegue", sender: nil)
                                case .engine:
                                    self.performSegue(withIdentifier: "toEngineSegue", sender: nil)
                                case .ac:
                                    self.performSegue(withIdentifier: "toACSegue", sender: nil)
                                case .tv:
                                    self.performSegue(withIdentifier: "tvRemote", sender: nil)
                                case .remotes:
                                    self.performSegue(withIdentifier: "customRemote", sender: nil)
                                case .wifi:
                                    self.performSegue(withIdentifier: "wifiRemote", sender: nil)
                                case .switchSenario:
                                    self.performSegue(withIdentifier: "toSwitchSenarioSegue", sender: nil)
                                case .inputStatus:
                                    self.performSegue(withIdentifier: "toInputStatusSegue", sender: nil)
                                case .cctv:
                                    self.performSegue(withIdentifier: "toCCTVSegue", sender: nil)
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
