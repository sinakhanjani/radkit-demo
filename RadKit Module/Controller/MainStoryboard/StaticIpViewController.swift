//
//  StaticIpViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 12/13/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class StaticIpViewController: UIViewController {

    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var stackView: UIStackView!

    var completion: ((_ ok:Bool) -> Void)?
    var device: Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.portTextField.keyboardType = .asciiCapableNumberPad
        self.ipTextField.keyboardType = .numbersAndPunctuation
        self.stackView.isHidden = true
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        completion?(false)
        dismiss(animated: true)
    }
    
    @IBAction func agreeButtonTapped(_ sender: Any) {
        if segmentControl.selectedSegmentIndex == 0 {
            device?.isStatic = false
            device?.staticIP = nil
            device?.staticPort = nil
        } else {
            guard !self.portTextField.text!.isEmpty && !self.ipTextField.text!.isEmpty else {
                self.presentIOSAlertWarning(message: "Enter port and IP", completion: {})
                return
            }
            device?.isStatic = true
            device?.staticIP = self.ipTextField.text
            device?.staticPort = self.portTextField.text
        }
        CoreDataStack.shared.saveContext()
        completion?(true)
        dismiss(animated: true)
    }
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        let index = (sender as! UISegmentedControl).selectedSegmentIndex
        if index == 0 {
            self.stackView.isHidden = true
        } else {
            self.stackView.isHidden = false
        }
    }

    static func create(completion: ((_ ok:Bool) -> Void)?) -> StaticIpViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "StaticIpViewController") as! StaticIpViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        
        return vc
    }
}
