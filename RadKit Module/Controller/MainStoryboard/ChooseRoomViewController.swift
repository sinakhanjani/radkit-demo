//
//  ChooseRoomViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/10/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import DropDown

class ChooseRoomViewController: UIViewController {

    @IBOutlet weak var roomButton: RoundedButton!
    @IBOutlet weak var bgView: UIView!

    var completion: ((_ room: Room?) -> Void)?
    var rooms = [Room]()
    var selectedRoom: Room?
    
    private let roomDropButton = DropDown()

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
            self.selectedRoom = self.rooms[index]
        }
    }
    
    @objc func endBGView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    static func create(completion: ((_ room: Room?) -> Void)?) -> ChooseRoomViewController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier:
        "ChooseRoomViewController") as! ChooseRoomViewController
        vc.completion = completion
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
    
    @IBAction func roomSelectedButtonTapped(_ sender: UIButton) {
        roomDropButton.show()
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        self.completion?(self.selectedRoom)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}
