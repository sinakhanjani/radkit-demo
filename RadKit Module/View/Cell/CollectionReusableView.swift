//
//  CollectionReusableView.swift
//  Master
//
//  Created by Sina khanjani on 11/17/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

protocol CollectionReusableViewDelegate: AnyObject {
    func reusableButtonTapped(cell: CollectionReusableView)
}

class CollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roundedView2: RoundedView!

    var currentIndexPath: IndexPath!
    weak var delegate: CollectionReusableViewDelegate?
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        delegate?.reusableButtonTapped(cell: self)
    }
}
