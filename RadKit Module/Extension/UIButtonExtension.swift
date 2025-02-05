//
//  UIButtonExtension.swift
//  Alaedin
//
//  Created by Sinakhanjani on 10/22/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit

extension UIButton {
    func tintImageColor(color: UIColor) {
        guard let image = self.imageView?.image else { return }
        self.setImage(image.withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
        self.tintColor = color
    }
}
