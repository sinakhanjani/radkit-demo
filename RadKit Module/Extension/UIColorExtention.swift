//
//  UIColorExtention.swift
//  Master
//
//  Created by Sina khanjani on 11/1/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

extension UIColor {
    func rgb() -> (red:Int, green:Int, blue:Int, alpha:Int)? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)

            return (red:iRed, green:iGreen, blue:iBlue, alpha:iAlpha)
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
    
    static let RADGreen = UIColor.init(named: "RADGreen")!
    static let baseGreen = UIColor.init(named: "baseGreen")!
}
