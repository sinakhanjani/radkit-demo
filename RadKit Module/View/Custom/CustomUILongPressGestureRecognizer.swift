//
//  CustomUILongPressGestureRecognizer.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/27/19.
//  Copyright © 2019 Sina Khanjani. All rights reserved.
//

import UIKit

class CustomUILongPressGestureRecognizer: UILongPressGestureRecognizer {
    
    var tag: Int
    
    init(target: Any?, action: Selector?, tag:Int) {
        self.tag = tag
        super.init(target: target, action: action)
    }

}
