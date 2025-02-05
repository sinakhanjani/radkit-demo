//
//  RoundedShadowView.swift
//  Master
//
//  Created by Sina khanjani on 10/11/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

//@IBDesignable
class RoundedShadowView: RoundedView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        super.setupView()
        addShadow()
    }
    
    @IBInspectable var shadowSize: CGFloat = 0.0 {
        didSet {
            addShadow()
        }
    }
    
    @IBInspectable var shadowColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) {
        didSet {
            addShadow()
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 0.0 {
        didSet {
            addShadow()
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0.0 {
        didSet {
            addShadow()
        }
    }
    
    func addShadow() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.04) {
            let shadowPath = UIBezierPath(rect: CGRect(x: -self.shadowSize / 2,
                                                       y: -self.shadowSize / 2,
                                                       width: self.frame.width + self.shadowSize,
                                                       height: self.frame.height + self.shadowSize))
            self.layer.masksToBounds = false
            self.layer.shadowColor = self.shadowColor.cgColor
            self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            self.layer.shadowOpacity = self.shadowOpacity
            self.layer.shadowRadius = self.shadowRadius
            self.layer.shadowPath = shadowPath.cgPath
            self.layoutIfNeeded()
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        super.setupView()
        addShadow()
    }
    
}
