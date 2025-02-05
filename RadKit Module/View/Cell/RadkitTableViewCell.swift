//
//  RadkitTableViewCell.swift
//  Master
//
//  Created by Sina khanjani on 6/14/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import UIKit

@objc protocol RadkitTableViewCellDelegate: AnyObject {
    @objc optional func button1Tapped(sender: UIButton, cell: RadkitTableViewCell)
    @objc optional func button2Tapped(sender: UIButton, cell: RadkitTableViewCell)
    @objc optional func button3Tapped(sender: UIButton, cell: RadkitTableViewCell)
    @objc optional func switchButtonValueChanged(sender: UISwitch, cell: RadkitTableViewCell)
    @objc optional func slider1ValueChanged(sender: UISlider, cell: RadkitTableViewCell)
    @objc optional func lognGestureTapped(sender: UILongPressGestureRecognizer,cell:RadkitTableViewCell)
}

protocol RadkitWeeklyTableViewCellDelegate: AnyObject {
    func lognGestureTappedWeekly(sender: UILongPressGestureRecognizer,cell:RadkitTableViewCell)
}

class RadkitTableViewCell: UITableViewCell {
    
    weak var delegate:RadkitTableViewCellDelegate?
    weak var weeklyDelegate:RadkitWeeklyTableViewCellDelegate?
    
    let passwordSwitch = UISwitch(frame: CGRect(x: UIScreen.main.bounds.width-64, y: 8, width: 60, height: 20))

    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var label_1: UILabel!
    @IBOutlet weak var label_2: UILabel!
    @IBOutlet weak var label_3: UILabel!
    @IBOutlet weak var label_4: UILabel!
    @IBOutlet weak var imageViewOne: UIImageView!
    @IBOutlet weak var imageViewTwo: UIImageView!
    @IBOutlet weak var imageViewThree: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var slider1: UISlider!
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var roundedView1: RoundedView!
    @IBOutlet weak var switchButton1: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        let touch = UILongPressGestureRecognizer.init(target: self, action: #selector(lognGestureTapped(_:)))
        self.addGestureRecognizer(touch)
    }
    
    @objc func lognGestureTapped(_ sender: UILongPressGestureRecognizer) {
        delegate?.lognGestureTapped?(sender: sender, cell: self)
        weeklyDelegate?.lognGestureTappedWeekly(sender: sender, cell: self)
    }
    
    @IBAction func button1Tapped(_ sender: UIButton) {
        delegate?.button1Tapped?(sender: sender, cell: self)
    }
    
    @IBAction func button2Tapped(_ sender: UIButton) {
        delegate?.button2Tapped?(sender: sender, cell: self)
    }
    
    @IBAction func button3Tapped(_ sender: UIButton) {
        delegate?.button3Tapped?(sender: sender, cell: self)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        delegate?.slider1ValueChanged?(sender: sender, cell: self)
    }
    
    @IBAction func switchButtonValueChanged(_ sender: UISwitch) {
        delegate?.switchButtonValueChanged?(sender: sender, cell: self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}

