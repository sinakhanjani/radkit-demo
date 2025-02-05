//
//  RoundedButton.swift
//  Cario
//
//  Created by Sinakhanjani on 7/21/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit

//@IBDesignable
class RoundedButton: UIButton {
    
    @IBInspectable var enText: String = "" {
        didSet {
            setupLanguage()
        }
    }
    
    @IBInspectable var faText: String = "" {
        didSet {
            setupLanguage()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    
    override func awakeFromNib() {
        setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
    func setupView() {
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        setupLanguage()
    }
    
    func setupLanguage() {
        if DataManager.shared.isMultiLanguage {
            if DataManager.shared.applicationLanguage == .en {
                self.setTitle(enText, for: .normal)
                self.setTitle(enText, for: .highlighted)
                self.setTitle(enText, for: .selected)
            } else {
                self.setTitle(faText, for: .normal)
                self.setTitle(faText, for: .highlighted)
                self.setTitle(faText, for: .selected)
            }
        }
    }
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        setupView()
    }
    
    override func reloadInputViews() {
        super.reloadInputViews()
        setupView()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        setupView()
    }
    
    
    
}
