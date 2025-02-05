//
//  DropEquipmentViewController.swift
//  Master
//
//  Created by Sina khanjani on 11/15/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit
import DropDown

enum OpenAs {
    case weekly
    case senario
    case none
}

class DropEquipmentViewController: UIViewController {

    @IBOutlet weak var roomButton: RoundedButton!
    @IBOutlet weak var equipmentButton: RoundedButton!
    @IBOutlet weak var bgView: UIView!

    var completion: ((_ equipment: Equipment?) -> Void)?
    var rooms = [Room]()
    var equipments = [Equipment]()
    var selectedEquipment: Equipment?
    var openAs: OpenAs = .none
    
    private let roomDropButton = DropDown()
    private let equipmentDropButton = DropDown()

    override func viewDidLoad() {
        super.viewDidLoad()
        bgView.dismissedKeyboardByTouch()
        let touch = UITapGestureRecognizer(target: self, action: #selector(endBGView))
        self.bgView.addGestureRecognizer(touch)
        roomDropButton.anchorView = roomButton
        roomDropButton.bottomOffset = CGPoint(x: 0, y: roomButton.bounds.height)
        roomDropButton.textFont = UIFont.persianFont(size: 14.0)
        if let rooms = CoreDataStack.shared.fetchRoomsInDatabase() {
            roomDropButton.dataSource = rooms.map { ($0.name ?? "") }
            self.rooms = rooms
        }
        roomDropButton.cellNib = UINib(nibName: "DropTableViewCell", bundle: nil)
        roomDropButton.customCellConfiguration = { [weak self] (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let self = self else { return }
           guard let cell = cell as? DropTableViewCell else { return }
            // Setup your custom UI components
            cell.optionLabel.text = self.rooms[index].name ?? ""
        }
        self.roomDropButton.selectionAction = { [weak self] (index, item) in
            guard let self = self else { return }
            self.roomButton.setTitle(item, for: .normal)
            if let equipments = CoreDataStack.shared.fetchEquipmentIn(theRoom: self.rooms[index]) {
                let items = equipments.filter({ eq in
                    if self.openAs == .senario {
                        return !eq.isShortcut && eq.type != Int64(9999) && eq.type != Int64(9997) && eq.type != Int64(9998)
                    } else if self.openAs == .weekly {
                        return !eq.isShortcut && eq.type != Int64(9999) && eq.type != Int64(9997)
                    } else {
                        return true
                    }
                })
                self.equipments = items
                self.equipmentDropButton.dataSource = items.map { ($0.name ?? "") }
                self.selectedEquipment = nil
                self.equipmentButton.setTitle("Appliance", for: .normal)
            }
        }

        equipmentDropButton.anchorView = equipmentButton
        equipmentDropButton.bottomOffset = CGPoint(x: 0, y: equipmentButton.bounds.height)
        equipmentDropButton.textFont = UIFont.persianFont(size: 14.0)
        equipmentDropButton.cellNib = UINib(nibName: "DropTableViewCell", bundle: nil)
        equipmentDropButton.customCellConfiguration = { [weak self] (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let self = self else { return }
           guard let cell = cell as? DropTableViewCell else { return }
            // Setup your custom UI components
            if let deviceType = DeviceType.init(rawValue: Int(self.equipments[index].type)) {
                let imgName = deviceType.imagename()
                cell.logoImageView.image = UIImage(named: imgName)
            }
            cell.optionLabel.text = self.equipments[index].name ?? ""
        }
        self.equipmentDropButton.selectionAction = { (index, item) in
            self.equipmentButton.setTitle(item, for: .normal)
            self.selectedEquipment = self.equipments[index]
        }
    }
    
    @objc func endBGView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    static func create(openAs: OpenAs, completion: ((_ equipment: Equipment?) -> Void)?) -> DropEquipmentViewController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier:
        "DropEquipmentViewController") as! DropEquipmentViewController
        vc.completion = completion
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.openAs = openAs
        
        return vc
    }
    
    @IBAction func roomSelectedButtonTapped(_ sender: UIButton) {
        roomDropButton.show()
    }
    
    @IBAction func equipmentSelectedButtonTapped(_ sender: UIButton) {
        equipmentDropButton.show()
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        self.completion?(self.selectedEquipment)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
