//
//  CustomRemoteViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/19/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//

import UIKit

class CustomRemoteViewController: UIViewController,RadKitCollectionViewCellDelegate,ConfigAdminRolles, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- CustomRemote")
        if tag == 19 {
            guard let device = device, let bytes = bytes else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let cell = dict?["cell"] as? RadKitCollectionViewCell {
                    cell.roundedView2.backgroundColor = .systemGray
                    //                    cell.button1.setBackgroundImage(UIImage(named: "click_none"), for: .normal)
                }
            }
            print("DONE SEND TO REMOTE",bytes,device.serial)
        }
    }
    
    func adminChanged() {
        self.admin()
    }
    
    private var completion: ((_ eqRelays: EQRely?,_ data:[UInt8]?) -> Void)?
    private var selectedEqRelays: EQRely?
    public var isSenario:Bool = false
    var sendItem: [UInt8]?
    var selectedIndexPath: IndexPath?
    
    static func create(viewController:UIViewController,equipment: Equipment,completion: ((_ eqRelays: EQRely?,_ data:[UInt8]?) -> Void)?) {
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CustomRemoteViewController") as! CustomRemoteViewController
        vc.isSenario = true
        vc.equipment = equipment
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.setViewControllers([vc], animated: true)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
        //        navigationController.navigationBar.barTintColor = #colorLiteral(red: 0, green: 0.6947382092, blue: 0.6967663169, alpha: 1)
        vc.completion = completion
        viewController.present(navigationController, animated: true, completion: nil)
    }
    @objc func doneSenarioButtonTapped() {
        if let selectedEqRelay = self.selectedEqRelays, let data = self.sendItem {
            var endData = data
            endData.remove(at: 1)
            self.completion?(selectedEqRelay,endData) // **
            self.dismiss(animated: true, completion: nil)
        } else {
            self.presentIOSAlertWarning(message: "Please select a learned remote") {}
        }
    }
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    ////??????
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var equipment: Equipment?
    var eqRelays: [EQRely]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        if isSenario {
            let img = UIImage(systemName: "checkmark")
            let img2 = UIImage(systemName: "chevron.down")
            let rightfBarButton = UIBarButtonItem(image: img, style: .plain, target: self, action: #selector(doneSenarioButtonTapped))
            //            rightfBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            let leftBarButton = UIBarButtonItem(image: img2, style: .plain, target: self, action: #selector(cancelButtonTapped))
            //            leftBarButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.navigationItem.rightBarButtonItem = rightfBarButton
            self.navigationItem.leftBarButtonItem = leftBarButton
            rightfBarButton.tintColor = .RADGreen
            leftBarButton.tintColor = .RADGreen
        } else {
            if let equipment = self.equipment {
                self.title = equipment.name
            }
        }
        fetchAllEQRelayInEquipment()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            self.collectionView.reloadData()
        }
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        if !isSenario {
            if let equipment = self.equipment {
                self.present(AddRelayViewController.create(equipment: equipment, completion: { [weak self] (selectedIndex,device, _) in
                    guard let self = self else { return }
                    if let equipment = self.equipment, let device = device, let _ = selectedIndex {
                        // add new button to DB
                        let index = self.eqRelays?.count ?? 0
                        CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: [Int64(index)])
                        self.fetchAllEQRelayInEquipment()
                    }
                }), animated: true, completion: nil)
            }
        }
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadKitCollectionViewCell) {
        if isSenario {
            //
        } else {
            //        guard let eqRelays = self.eqRelays else { return }
            if let indexPath = collectionView.indexPath(for: cell) {
                //                       let item = eqRelays[indexPath.item]
                switch sender.state {
                case .possible:
                    break
                case .began:
                    print(indexPath)
                    let message = ""
                    //                                       let title = NSAttributedString(string: "Edit custom remote", attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 17.0)!, NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.08911790699, green: 0.08914073557, blue: 0.08911494166, alpha: 1)])
                    //                                       let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.black])
                    
                    let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
                    //                                       alertController.setValue(attributeMsg, forKey: "attributedMessage")
                    //                                       alertController.setValue(title, forKey: "attributedTitle")
                    let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { (action) in
                        //
                    }
                    let changeName = UIAlertAction.init(title: "Rename", style: .default) { [weak self] (action) in
                        if let items = self?.eqRelays {
                            self?.presentAlertActionWithTextField(message: "Please enter the new name of the remote", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                                guard let self = self else { return }
                                CoreDataStack.shared.updateEQRelayName(eqRelay: items[indexPath.item], name: name)
                                self.collectionView.reloadItems(at: [indexPath])
                            }
                        }
                    }
                    let remove = UIAlertAction.init(title: "Remove Remote", style: .default) { [weak self] (action) in
                        if let items = self?.eqRelays {
                            self?.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this remote?", buttonOneTitle: "Yes", buttonTwoTitle: "No", handlerButtonOne: { [weak self] in
                                CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: items[indexPath.item])
                                self?.fetchAllEQRelayInEquipment()
                            }) {
                                //
                            }
                        }
                    }
                    let learn = UIAlertAction.init(title: "Learning Remote", style: .default) { [weak self] (action) in
                        if let eqRelays = self?.eqRelays {
                            self?.learnRemote(index: indexPath.item, eqRelay: eqRelays[indexPath.item])
                        }
                    }
                    let changeIcon = UIAlertAction.init(title: "Change Icon", style: .default) { [weak self] (action) in
                        guard let self = self else { return }
                        if let items = self.eqRelays {
                            let item = items[indexPath.item]
                            let vc = PhotoPickupViewController.create {[weak self] data in
                                guard let self = self else { return }
                                if let data = data {
                                    CoreDataStack.shared.updateEQRelay(cover: data, eqRelay: item)
                                    self.collectionView.reloadData()
                                }
                            }
                            self.present(vc, animated: true)
                        }
                    }
                    changeIcon.setValue(UIColor.RADGreen, forKey: "titleTextColor")

                    alertController.addAction(changeIcon)
                    cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
                    //                                       learn.setValue(UIColor.black, forKey: "titleTextColor")
                    //                                       changeName.setValue(UIColor.black, forKey: "titleTextColor")
                    //                                       remove.setValue(UIColor.black, forKey: "titleTextColor")
                    alertController.addAction(cancelAction)
                    learn.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                    alertController.addAction(learn)
                    if Password.shared.adminMode {
                        changeName.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                        alertController.addAction(changeName)
                        remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                        alertController.addAction(remove)
                    }
                    self.present(alertController, animated: true, completion: nil)
                case .changed:
                    break
                case .ended:
                    break
                case .cancelled:
                    break
                case .failed:
                    break
                default:
                    break
                }
            }
        }
    }
    
    func button1Tapped(sender: UIButton, cell: RadKitCollectionViewCell) {
        guard let eqRelays = self.eqRelays else {
            return
        }
        if isSenario {
            if let indexPath = self.collectionView.indexPath(for: cell) {
                if let data = eqRelays[indexPath.item].data {
                    self.sendItem = data.bytes
                    self.selectedEqRelays = eqRelays[indexPath.item]
                    self.selectedIndexPath = indexPath
                    self.collectionView.reloadData()
                }
            }
        } else {
            
            if let indexPath = self.collectionView.indexPath(for: cell) {
                if let data = eqRelays[indexPath.item].data {
                    cell.roundedView2.backgroundColor = .blue
                    //                    cell.button1.setBackgroundImage(UIImage(named: "click_blue"), for: .normal)
                    self.sendToRemote(data: data, type: .directRequest,cell: cell)
                } else {
                    self.learnRemote(index: indexPath.item, eqRelay: eqRelays[indexPath.item])
                }
            }
        }
    }
    
    func learnRemote(index:Int,eqRelay: EQRely?) {
        TwoActionViewController.create(viewController: self, title: "Learning", subtitle: "After hitting the learn button, hold the remote in front of the device and press the desired button", completionHandlerButtonOne: {
            //cancel//
        }) { [weak self] in
            
            guard let self = self else { return }
            
            // yadgiri
            guard let equipment = self.equipment else {
                return
            }
            guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
                return
            }
            guard !eqDevices.isEmpty else {
                return
            }
            guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevices[0]) else {
                return
            }
            OneActionAlertViewController.create(viewController: self, title: "Learning", subtitle: "Please press the remote button",device: device,digit: Int64(index),equipment: equipment,isCustom: eqRelay) { [weak self] bytes in
                guard let self = self else { return }
                // waiting for button until 15secend*
                if bytes == nil {
                    // cancel request *
                    let sendByte = [UInt8(7)]
                    var inputBytes: [UInt8] = sendByte
                    let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
                    let data = Data.init(referencing: nsdata)
                    self.sendToRemote(data: data, type: .otherRequest)
                } else {
                    NWSocketConnection.instance.delegate = self
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.fetchAllEQRelayInEquipment()
                    }
                }
            }
        }
    }
    
    func sendToRemote(data:Data,type:TypeRequest,cell:RadKitCollectionViewCell?=nil) {
        guard let equipment = self.equipment else {
            return
        }
        guard let eqDevices = CoreDataStack.shared.fetchEQDevicesInEquipment(equipment: equipment) else {
            return
        }
        guard !eqDevices.isEmpty else {
            return
        }
        guard let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: eqDevices[0]) else {
            return
        }
        var sendBytes = data.bytes
        if sendBytes.count > 1 {
            sendBytes.remove(at: 1)
        }
        print("FINAL SEND:\(sendBytes)")
        var dict: [String:Any]?
        if let cell = cell {
            dict = ["cell": cell]
        }
        NWSocketConnection.instance.send( dict: dict,tag:19,device: device, typeRequest: type,data: sendBytes) { [weak self] (bytes, device) in
            //            guard let self = self else { return }
            //            guard let device = device, let bytes = bytes else {
            //                return
            //            }
            //            DispatchQueue.main.async { [weak self] in
            //                guard let self = self else { return }
            //                if cell != nil {
            //                    cell!.button1.setBackgroundImage(UIImage(named: "click_none"), for: .normal)
            //                }
            //            }
            //            print("DONE SEND TO REMOTE",bytes,device.serial)
        }
    }
}

extension CustomRemoteViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.eqRelays?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "centerMainCollectionView", for: indexPath) as! RadKitCollectionViewCell
        if let items = self.eqRelays {
            let item = items[indexPath.item]
            if let cover = item.cover {
                cell.button1.setBackgroundImage(UIImage(data: cover), for: .normal)
            } else {
                cell.button1.setBackgroundImage(UIImage(named: "d20"), for: .normal)
            }
            var serial = "\(item.eqDevice?.serial ?? 0)"
            if serial.count < 6 {
                while serial.count < 6 {
                    serial = "0" + serial
                }
            }
            
            cell.label1.text = String(serial)
            if item.name == nil {
                cell.label2.text = "R-" + "\(indexPath.item+1)"
            } else {
                cell.label2.text = item.name
            }
            cell.roundedView2.backgroundColor = .systemGray
            //            cell.button1.setBackgroundImage(UIImage(named: "click_none"), for: .normal)
        }
        cell.delegate = self
        if isSenario {
            if let item = self.eqRelays?[indexPath.item] {
                if let cover = item.cover {
                    cell.button1.setBackgroundImage(UIImage(data: cover), for: .normal)
                } else {
                    cell.button1.setBackgroundImage(UIImage(named: "d20"), for: .normal)
                }
            }
            //
            if let selectedIndex = self.selectedIndexPath {
                if indexPath.item == selectedIndex.item {
                    if self.eqRelays?[indexPath.item].name == nil {
                        self.eqRelays?[indexPath.item].name = "R-" + "\(indexPath.item+1)"
                    }
                    cell.roundedView2.backgroundColor = .blue
                    //                    cell.button1.setBackgroundImage(UIImage(named: "click_blue"), for: .normal)
                } else {
                    cell.roundedView2.backgroundColor = .systemGray
                    //                    cell.button1.setBackgroundImage(UIImage(named: "click_none"), for: .normal)
                }
            } else {
                cell.roundedView2.backgroundColor = .systemGray
                //                cell.button1.setBackgroundImage(UIImage(named: "click_none"), for: .normal)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numberOfColumns: CGFloat = 2
        if UIScreen.main.bounds.width > 320 {
            numberOfColumns = 3
        }
        let spaceBetweenCells: CGFloat = 10
        let padding: CGFloat = 40
        let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns
        
        return CGSize.init(width: cellDimention, height: 128)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //
    }
}
