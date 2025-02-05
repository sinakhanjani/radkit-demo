//
//  AboutusViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class AboutusViewController: UIViewController {

    @IBOutlet weak var tokenTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backBarButtonAttribute(color: .white, name: "")
        // Do any additional setup after loading the view.
        self.title = "About Us"
    }
}
