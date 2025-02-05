//
//  RadKitCollectionViewCell.swift
//  Master
//
//  Created by Sina khanjani on 9/29/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

@objc protocol RadKitCollectionViewCellDelegate: AnyObject {
    @objc optional func lognGestureTapped(sender: UILongPressGestureRecognizer,cell:RadKitCollectionViewCell)
    @objc optional func button1Tapped(sender:UIButton,cell:RadKitCollectionViewCell)
    @objc optional func button2Tapped(sender:UIButton,cell:RadKitCollectionViewCell)

}

class RadKitCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var roundedView1: RoundedView!
    @IBOutlet weak var roundedView2: RoundedView!
    @IBOutlet weak var pageControl: UIPageControl!

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!

    weak var delegate:RadKitCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let touch = UILongPressGestureRecognizer.init(target: self, action: #selector(lognGestureTapped(_:)))
        self.addGestureRecognizer(touch)
    }

    @objc func lognGestureTapped(_ sender: UILongPressGestureRecognizer) {
        delegate?.lognGestureTapped?(sender: sender, cell: self)
    }
    
    @IBAction func button1Tapped(_ sender: UIButton) {
        delegate?.button1Tapped?(sender: sender, cell: self)
    }
    
    
    @IBAction func button2Tapped(_ sender: UIButton) {
        delegate?.button2Tapped?(sender: sender, cell: self)
    }
    
}
