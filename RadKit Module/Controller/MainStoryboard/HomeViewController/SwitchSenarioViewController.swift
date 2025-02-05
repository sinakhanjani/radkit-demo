//
//  SwitchSenarioViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 7/18/1399 AP.
//  Copyright © 1399 Sina Khanjani. All rights reserved.
//

import UIKit

extension SwitchSenarioViewController: NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        print("TAG \(tag)- SwitchSenario")
        if (tag == 218) || (tag == 1111 && dict?["hearth"] == nil) {
            guard let cell = dict?["cell"] as? RadKitCollectionViewCell else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("income bytes:",bytes ?? [UInt8]())
                cell.roundedView2.backgroundColor = .systemGray
//                cell.button1.setBackgroundImage(UIImage.init(named: "click_none"), for: .normal)
            }
        }
    }
}

class SwitchSenarioViewController: UIViewController, RadKitCollectionViewCellDelegate,ConfigAdminRolles {
    
    func adminChanged() {
        self.admin()
    }

    @IBOutlet weak var collectionView: UICollectionView!
    
    var equipment: Equipment?
    var eqRelays: [EQRely]?

    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
//        NWSocketConnection.instance.delegate = self
        backBarButtonAttribute(color: .label, name: "")
        if let equipment = self.equipment {
            self.title = equipment.name
        }
        fetchAllEQRelayInEquipment()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NWSocketConnection.instance.delegate = self
    }
    
    func lognGestureTapped(sender: UILongPressGestureRecognizer, cell: RadKitCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            switch sender.state {
            case .possible:
                break
            case .began:
                let message = "Choose your settings"
//                let title = NSAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 17.0)!, NSAttributedString.Key.foregroundColor : #colorLiteral(red: 0.08911790699, green: 0.08914073557, blue: 0.08911494166, alpha: 1)])
//                let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.black])

                let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
//                alertController.setValue(attributeMsg, forKey: "attributedMessage")
//                alertController.setValue(title, forKey: "attributedTitle")
                let cancelAction = UIAlertAction.init(title:"Cancel", style: .cancel) { (action) in
                    //
                }
                let changeName = UIAlertAction.init(title: "Rename", style: .default) { [weak self] (action) in
                    if let items = self?.eqRelays {
                        self?.presentAlertActionWithTextField(message: "Please enter a new name", title: "Rename", textFieldPlaceHolder: "Write the name") { [weak self] (name) in
                            CoreDataStack.shared.updateEQRelayName(eqRelay: items[indexPath.item], name: name)
                            self?.collectionView.reloadItems(at: [indexPath])
                        }
                    }
                }
                let remove = UIAlertAction.init(title: "Delete Output", style: .default) { [weak self] (action) in
                    if let items = self?.eqRelays {
                        self?.presentIOSAlertWarningWithTwoButton(message: "Do you want to delete this output?", buttonOneTitle: "Yes", buttonTwoTitle:"No", handlerButtonOne: { [weak self] in
                            CoreDataStack.shared.removeEQRelayInDatabse(eqRelay: items[indexPath.item])
                            self?.fetchAllEQRelayInEquipment()
                        }) {
                            //
                        }
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
//                remove.setValue(UIColor.black, forKey: "titleTextColor")
//                changeName.setValue(UIColor.black, forKey: "titleTextColor")
                
                alertController.addAction(cancelAction)
                changeName.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                alertController.addAction(changeName)
                remove.setValue(UIColor.RADGreen, forKey: "titleTextColor")
                alertController.addAction(remove)
                if Password.shared.adminMode {
                    self.present(alertController, animated: true, completion: nil)
                }
            case .changed:
                break
            case .ended:
                self.collectionView.isUserInteractionEnabled = true
            case .cancelled:
                break
            case .failed:
                break
            default:
                break
            }
        }
    }

    // add sc barbutton tapped
    @IBAction func addButtonTapped(_ sender: Any) {
        if let equipment = self.equipment {
            let nav = AddRelayViewController.create(equipment: equipment, completion: { [weak self] (_,device, incomeData) in
                guard let self = self else { return }
                if let equipment = self.equipment, let device = device ,let incomeData = incomeData {
                    let int64: [Int64] = [0]
                    CoreDataStack.shared.addEQDeviceWithEQRelayToEquipment(addToequipment: equipment, device: device, digitsIndex: int64, data: incomeData, isSwitchSenario: true)
                    self.fetchAllEQRelayInEquipment()
                }
            })
            (nav.viewControllers.first as! AddRelayViewController).type = "switchSenario"
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func fetchAllEQRelayInEquipment() {
        if let equipment = self.equipment {
            self.eqRelays = CoreDataStack.shared.fetchEqRelaysInAllEQDevices(equipment: equipment)
            self.collectionView.reloadData()
        }
    }

    // sc button Tapped:
    func button1Tapped(sender: UIButton, cell: RadKitCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            if let items = self.eqRelays {
                let item = items[indexPath.item]
                if let data = item.data {
                    print("send bytes",data.bytes)
                    if let device = CoreDataStack.shared.findRealDeviceInEquipment(equipmentEQDevice: item.eqDevice!) {
                        cell.roundedView2.backgroundColor = .blue
//                        cell.button1.setBackgroundImage(UIImage.init(named: "click_blue"), for: .normal)
                        NWSocketConnection.instance.send(dict: ["cell": cell],tag:218,device: device, typeRequest: .switchSenarioRequest,data: data.bytes) { [weak self] (bytes, device) in
//                            guard let self = self else { return }
//                            DispatchQueue.main.async { [weak self] in
//                                guard let self = self else { return }
//                                print("income bytes:",bytes ?? [UInt8]())
//                                cell.button1.setBackgroundImage(UIImage.init(named: "click_none"), for: .normal)
//                            }
                        }
                    }
                }
            }
        }
    }
}

extension SwitchSenarioViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.eqRelays?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "centerMainCollectionView", for: indexPath) as! RadKitCollectionViewCell
        cell.delegate = self
//        cell.button1.setBackgroundImage(UIImage.init(named: "click_highlight"), for: .highlighted)
//        cell.button1.setBackgroundImage(UIImage.init(named: "click_highlight"), for: .selected)
//        cell.button1.setBackgroundImage(UIImage.init(named: "click_none"), for: .normal)
        cell.roundedView2.backgroundColor = .systemGray
        if let items = self.eqRelays {
            let item = items[indexPath.item]
            if let cover = item.cover {
                cell.button1.setBackgroundImage(UIImage(data: cover), for: .normal)
            } else {
                cell.button1.setBackgroundImage(UIImage(named: "d21"), for: .normal)
            }
            
            var serial = "\(item.eqDevice?.serial ?? 0)"
            if serial.count < 6 {
                while serial.count < 6 {
                    serial = "0" + serial
                }
            }
            
            cell.label1.text = "R\(Int(item.digit)+1)-S/\(serial)"
            cell.label2.text = item.name
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
