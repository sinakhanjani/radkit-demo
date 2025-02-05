//
//  SenarioWeeklyViewController.swift
//  Master
//
//  Created by Sina khanjani on 11/15/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

class SenarioWeeklyViewController: UIViewController,RadKitCollectionViewCellDelegate,UITextFieldDelegate, ConfigAdminRolles {
    func adminChanged() {
        admin()
        if Password.shared.adminMode {
            self.addButton.isEnabled = true
        } else {
            self.addButton.isEnabled = false
        }
    }
    
    private var completion: ((_ device: Device?) -> Void)?
    private var senarioSendDataController = SenarioSendDataController(senarioType: .weekly)
    
    let senarioConnection = SenarioConnection()
    
    @IBOutlet weak var addButton: RoundedButton!
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var relayNameLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var roundColorView: RoundedView!
    @IBOutlet weak var itemAddedBoxView: UIView!
    
    
    @IBOutlet weak var fadeSlider: UISlider!
    @IBOutlet weak var fadeTimeLabel: UILabel!
    @IBOutlet weak var fadeView: UIView!
    
    var fadeValue: UInt8 = UInt8(110)
    
    var equipment: Equipment?
    var device: Device? {
        willSet {
            if let newValue = newValue {
                if let deviceType = DeviceType.init(rawValue: Int(newValue.type)), let equipment = equipment {
                    if (deviceType == .dimmer || deviceType == .rgbController) && (equipment.type == UInt64(04) || equipment.type == UInt64(09)) {
                        self.fadeView.alpha = 1
                        self.fadeValue = UInt8(110)
                        self.fadeTimeLabel.text = "0 Minute"
                    } else {
                        self.fadeView.alpha = 0
                    }
                }
            }
        }
    }
    var pastByte: [UInt8]?
    
    private var selectedIndexes: [Int] = []

    var dateNames = ["S",
                     "S",
                     "M",
                     "T",
                     "W",
                     "T",
                     "F",
]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        self.fadeView.alpha = 0
        addButton.tintImageColor(color: .white)
        self.titleLabel.delegate = self
        self.view.dismissedKeyboardByTouch()
        backBarButtonAttribute(color: .white, name: "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func fadeSliderValueChanhed(_ sender: UISlider) {
        self.fadeTimeLabel.text = "\(Int(sender.value)) minute"
        self.fadeValue = UInt8(Int(sender.value)+110)
    }

    @IBAction func addButtonTapped(_ sender: Any) {
        guard let name = self.titleLabel.text, name != "" else {
            self.presentIOSAlertWarning(message: "Please choose a name for the weekly schedule.") {
                //
            }
            self.view.endEditing(true)
            return
        }
        guard self.device != nil && self.pastByte != nil else {
            self.presentIOSAlertWarning(message: "Select an output from a device for the weekly schedule") {
                //
            }
            self.view.endEditing(true)
            return
        }

        let hour = datePicker.date.PersianDateHour()
        let minute = datePicker.date.PersianDateMinute()
        var days = [0,0,0,0,0,0,0]
        for item in self.selectedIndexes {
            days[item] = 1
        }
        
        var finalPastByte: [UInt8] = self.pastByte ?? []
        // this condition is only for rgb and dimmer
        if let device = self.device {
            if let deviceType = DeviceType.init(rawValue: Int(device.type)), let equipment = self.equipment {
                if (deviceType == .dimmer || deviceType == .rgbController) && (equipment.type == UInt64(04) || equipment.type == UInt64(09)) {
                    if let pastByte = pastByte, pastByte.count >= 9 {
                        if finalPastByte[7] == UInt8(101) {
                            finalPastByte[7] = self.fadeValue
                        }
                        if finalPastByte[8] == UInt8(101) {
                            finalPastByte[8] = self.fadeValue
                        }
                    }
                }
            }
        }
        // create weekly and send request
        senarioConnection.createWeekly(vc: self, recievedByte: finalPastByte, device: device, hour: Int(hour)!, minute: Int(minute)!, day: days, name: titleLabel.text!)
        self.completion?(device)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addEqiupmentButtonTapped2(_ sender: Any) {
        self.present(DropEquipmentViewController.create(openAs: .weekly, completion: { (equipment) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.48) { [weak self] in
                guard let self = self else { return }
                if let equipment = equipment {
                    self.equipment = equipment
                    self.senarioSendDataController.presnetEquipmentInWeekly(self, equipment: equipment) { [weak self] (bytes, device,eqRelay) in
                        guard let self = self else { return }
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.0) { [weak self] in
                            guard let self = self else { return }
                            guard let device = device, let bytes = bytes,let eqRelay = eqRelay else { return }
                            self.device = device
                            self.pastByte = bytes
//                            self.relayNameLabel.text = "\(eqRelay.name ?? "")"
                            if let deviceType = DeviceType.init(rawValue: Int(device.type)) {
                                switch deviceType {
                                case .switch12_0,.switch12_1,.switch12_2,.switch12_3,.switch6,.switch6_13,.switch6_14,.switch6_15, .switch1, .switch12_sim_0:
                                    if bytes[1] == UInt8(0) {
                                        self.roundColorView.backgroundColor = .red
//                                        self.addButton.setImage(UIImage(named: "click_red"), for: .normal)
                                    } else {
                                        self.roundColorView.backgroundColor = .baseGreen
//                                        self.addButton.setImage(UIImage(named: "click_green"), for: .normal)
                                    }
                                default:
                                    self.roundColorView.backgroundColor = .darkGray
                                    self.addButton.setImage(UIImage(named: "click_none"), for: .normal)
                                }
                                self.addButton.backgroundColor = .clear
                                self.addButton.setTitle("", for: .normal)
                                self.addButton.alpha = 0
                                self.itemAddedBoxView.alpha = 1
                                self.itemNameLabel.text = "\(eqRelay.name ?? "")"
                            }
                        }
                    }
                }
            }
        }), animated: true, completion: nil)
    }
    
    static func create(completion: ((_ device: Device?) -> Void)?) -> UINavigationController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nav = mainStoryboard.instantiateViewController(withIdentifier:
        "SenarioWeeklyViewController") as! UINavigationController
        let vc = nav.viewControllers.first as! SenarioWeeklyViewController
        vc.completion = completion
        return nav
    }
    
    func button1Tapped(sender: UIButton, cell: RadKitCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? RadKitCollectionViewCell else { return }
            let index = self.selectedIndexes.lastIndex { (dat) -> Bool in
                if dat == indexPath.item {
                    return true
                }
                return false
            }
            if let index = index {
                self.selectedIndexes.remove(at: index)
                cell.roundedView1.borderColor = .clear
                cell.label1.textColor = .lightGray
                if indexPath.item == 6 {
                    cell.label1.textColor = .red
                }
            } else {
                cell.roundedView1.borderColor = Constant.Colors.green
                self.selectedIndexes.append(indexPath.item)
                cell.label1.textColor = Constant.Colors.green
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 15
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        
        return newString.length <= maxLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension SenarioWeeklyViewController: UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dateNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RadKitCollectionViewCell
        cell.label1.text = dateNames[indexPath.item]
        if indexPath.item == 1 {
            cell.label1.textColor = .red
        }
        cell.delegate = self
//        cell.label1.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        return cell
    }
    
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let numberOfColumns: CGFloat = 7
            let spaceBetweenCells: CGFloat = 4
            let padding: CGFloat = 16
            let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns
    
            return CGSize.init(width: cellDimention, height: cellDimention)
    
        }


}
