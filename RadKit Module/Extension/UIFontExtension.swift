//
//  UIFont.swift
//  Alaedin
//
//  Created by Sinakhanjani on 10/21/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit

extension UIFont {
    static func persianFont(size: CGFloat) -> UIFont {
        return UIFont.init(name: Constant.Fonts.fontOne, size: size)!
    }
}
