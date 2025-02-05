//
//  SenarioCommandViewController.swift
//  Master
//
//  Created by Sina khanjani on 11/15/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

class SenarioCommandViewController: UIViewController,RadKitCollectionViewCellDelegate,UITextFieldDelegate,ConfigAdminRolles, CollectionReusableViewDelegate {
    func adminChanged() {
        admin()
        if Password.shared.adminMode {
            self.addEquipButton.isEnabled = true
        } else {
            self.addEquipButton.isEnabled = false
        }
    }
    
    @IBOutlet weak var tedadEjraView: UIView!
    @IBOutlet weak var tedadEjraButtonTapped: UIButton!
    @IBOutlet weak var addEquipButton: RoundedButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    enum VCHistory {
        case old
        case new
    }
    var addedIndexChanged = [Int:Double]()
    
    private var vcHistory: VCHistory = .old
    private var senario: Senario?
    private var completion: ((_ senario: Senario?) -> Void)?
    private var senarioSendDataController = SenarioSendDataController(senarioType: .senario)
    private var commands: [Command] = []
    var isNewSenario = false
    var newSenarioRepeatedTime: Int = 0 {
        willSet {
            if newValue == 100 {
                self.tedadEjraButtonTapped.setTitle("Run Times: Infinite", for: .normal)
            } else {
                self.tedadEjraButtonTapped.setTitle("Run Times: \(newValue)", for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adminAccess()
        addEquipButton.tintImageColor(color: .white)
        self.nameTextField.delegate = self
//        addEquipButton.bindToKeyboard()
        view.dismissedKeyboardByTouch()
        backBarButtonAttribute(color: .white, name: "")
        
        self.tedadEjraButtonTapped.setTitle("Run Times: \(self.newSenarioRepeatedTime)", for: .normal)
        
        if let senario = senario {
            self.vcHistory = .old
            self.nameTextField.text = senario.name
            self.commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
            self.checkForRunTimeShown()
        } else {
            self.tedadEjraView.alpha = 0
            vcHistory = .new
        }
    }
    
    func checkForRunTimeShown() {
        if let senario = senario {
            if !self.commands.isEmpty {
                SenarioSendDataV2Controller.run(viewController: self, senario) { dict in
                    if let _ = dict {
                        if senario.repeatedTime == 0 {
                            self.newSenarioRepeatedTime = 1
                        } else {
                            self.newSenarioRepeatedTime = Int(senario.repeatedTime)
                        }
                        self.tedadEjraView.alpha = 1
                        self.isNewSenario = true
                    } else {
                        self.tedadEjraView.alpha = 0
                        self.isNewSenario = false
                    }
                }
            }
        } else {
            self.isNewSenario = false
            self.tedadEjraView.alpha = 0
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func repeatedTimeButtonTapped() {
        PickerViewController.create(viewController: self, title: "Scenario Run Times", isSetting: false ,isAnother: true) { [weak self] (result) in
            guard let self = self else { return }
            if let result = result {
                self.newSenarioRepeatedTime = result
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        if self.vcHistory == .new {
            if let senario = senario {
                CoreDataStack.shared.removeSenario(senario)
            }
        } else {
            for (index,value) in addedIndexChanged {
                commands[index].time = value
            }
            addedIndexChanged.removeAll()
            CoreDataStack.shared.saveContext()
        }
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        guard let name = self.nameTextField.text, name != "" else {
            self.presentIOSAlertWarning(message: "Please choose a name for the script.") {
                //
            }
            self.view.endEditing(true)
            return
        }
        guard let senario = self.senario else {
            self.presentIOSAlertWarning(message:"Choose to run at least one command for this scenario") {
                //
            }
            self.view.endEditing(true)
            return
        }
        self.view.endEditing(true)
        CoreDataStack.shared.changeSenario(senario, name, repeatedTime: newSenarioRepeatedTime)
        self.completion?(self.senario)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addnewEquip(_ sender: Any) {
        self.view.endEditing(true)
        self.present(DropEquipmentViewController.create(openAs: .senario, completion: { [weak self] (equipment) in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.4) { [weak self] in
                guard let self = self else { return }
                if let equipment = equipment {
                    self.senarioSendDataController.presnetEquipmentInSenario(self, equipment: equipment, senario: self.senario,repeatedTime: self.newSenarioRepeatedTime) { [weak self] (state) in
                        guard let self = self else { return }
                        switch state {
                        case .new:
                            print(".new")
                            self.senario = CoreDataStack.shared.fetchSenarios().last
                            if let senario = self.senario {
                                self.commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
                                self.collectionView.reloadData()
                                self.checkForRunTimeShown()
                            }
                        case .old:
                            print(".old")
                            if let senario = self.senario {
                                self.commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
                                self.collectionView.reloadData()
                                self.checkForRunTimeShown()
                            }
                        case .failed:
                            print(".failed")
                        case .update:
                            break
                        }
                    }
                }
            }
        }), animated: true, completion: nil)
    }
    
    static func create(senario: Senario?,completion: ((_ senario: Senario?) -> Void)?) -> UINavigationController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let nav = mainStoryboard.instantiateViewController(withIdentifier:
        "SenarioCommandViewController") as! UINavigationController
        let vc = nav.viewControllers.first as! SenarioCommandViewController
        vc.senario = senario
        vc.completion = completion
        return nav
    }

    func button1Tapped(sender: UIButton, cell: RadKitCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let command = self.commands[indexPath.section]
        let lastTime = command.time
        self.addedIndexChanged.updateValue(lastTime, forKey: indexPath.section)
        self.present(TimeViewController.create(lastTime: lastTime, type: .time) { [weak self] (time) in
            guard let self = self else { return }
            if let time = time {
                self.commands[indexPath.section].time = time
                self.collectionView.reloadData()
            }
        }, animated: true, completion: nil)
    }
    
    func reusableButtonTapped(cell: CollectionReusableView) {
        self.view.endEditing(true)
        let section = cell.currentIndexPath.section
        let command = self.commands[section]
        self.present(DropEquipmentViewController.create(openAs: .senario, completion: { [weak self] (equipment) in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.4) { [weak self] in
                guard let self = self else { return }
                if let equipment = equipment {
                    self.senarioSendDataController.presnetEquipmentInSenario(self, equipment: equipment, senario: self.senario,command: command, repeatedTime: self.newSenarioRepeatedTime) { [weak self] (state) in
                        guard let self = self else { return }
                        switch state {
                        case .update:
                            print(".update")
                            if let senario = self.senario {
                                self.commands = CoreDataStack.shared.fetchCommandOn(senario: senario)
                                self.collectionView.reloadData()
                            }
                        default:
                            break
                        }
                    }
                }
            }
        }), animated: true, completion: nil)
    }
}


extension SenarioCommandViewController: UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.commands.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if commands.count-1 == section {
            if isNewSenario {
                return 1
            } else {
                return 0
            }
        }
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RadKitCollectionViewCell
        let time = self.commands[indexPath.section].time
//        let command = commands[indexPath.section]
        var title = ""
        if time >= 0.5 && time <= 20 {
            title = "\(time) Second"
        }
        if time >= 21.0 && time <= 59 {
            title = "\(time) Second"
        }
        if time >= 60.0 && time <= 300.0 {
            let minute = time/60.0
            title = "\(Int(minute)) Minute"
        }
        if time >= 600.0 && time <= (50*60.0) {
            let minute = time/60.0
            title = "\(Int(minute)) Minutes"
        }
        if time == (3600.0) {
            title = "1 Hour"
        }
        
        cell.button1.setTitle(title, for: .normal)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: UIScreen.main.bounds.width, height: 46.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionCell", for: indexPath) as! CollectionReusableView
        sectionHeaderView.delegate = self
        sectionHeaderView.currentIndexPath = indexPath
        let command = self.commands[indexPath.section]
        
        if let name = command.deviceName {
            sectionHeaderView.nameLabel.text = name
        } else {
            if let deviceType = DeviceType.init(rawValue: Int(command.deviceType)) {
            switch deviceType {
            case .tv:
                sectionHeaderView.nameLabel.text = "TV"
            default:
                break
                }
            }
        }
        if let deviceType = DeviceType.init(rawValue: Int(command.deviceType)) {
            switch deviceType {
            case .switch12_0,.switch12_1,.switch12_2,.switch12_3,.switch6,.switch6_13,.switch6_14,.switch6_15,.switch1, .switch12_sim_0:
                if let data = command.sendData {
                    let bytes = data.bytes
                    if bytes[1] == UInt8(0) {
                        sectionHeaderView.roundedView2.backgroundColor = .red
                    } else {
                        sectionHeaderView.roundedView2.backgroundColor = .baseGreen
                    }
                }
            default:
                sectionHeaderView.roundedView2.backgroundColor = .systemBackground
            }
        }
        return sectionHeaderView
    }
}
