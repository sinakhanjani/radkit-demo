//
//  IndicatorViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class IndicatorViewController: UIViewController {

    var completion: ((_ ok:Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    static func create(completion: ((_ ok:Bool) -> Void)?) -> IndicatorViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "IndicatorViewController") as! IndicatorViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        
        return vc
    }
}
