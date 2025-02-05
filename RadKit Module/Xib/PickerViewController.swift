//
//  PickerViewController.swift
//  Master
//
//  Created by Sina khanjani on 10/25/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!

    var selectedItem: Int?
    var titleName: String?
    private var escape: ((_ data: Int?) -> Void)?

    var isSetting: Bool = true
    var isHum: Bool = false
    var isAnother: Bool = false
    var data = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        let touch = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.bgView.addGestureRecognizer(touch)
        if let titleName = self.titleName {
            self.titleLabel.text = titleName
        }
        
        if self.isHum {
            symbolLabel.text = "%"
        } else {
            if isAnother {
                symbolLabel.text = ""
            } else {
                symbolLabel.text = "°C"
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        selectedItem = Int(data[0])!
    }
    
    func setData() {
        var items = [String]()
        if isAnother {
            for i in 1...100 {
                items.append(String(i))
            }
        } else {
            if isHum {
                if isSetting {
                    for i in 0..<101 {
                        items.append(String(i))
                    }
                } else {
                    for i in 1...50 {
                        items.append(String(i))
                    }
                }
            } else {
                if isSetting {
                    for i in 1..<16 {
                        items.append(String(i))
                    }
                } else {
                    for i in 0..<66 {
                        items.append(String(i))
                    }
                }
            }
        }

        self.data = items
    }
    
    @objc func tapped() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func agreeButtonTapped(_ sender: Any) {
        self.escape?(self.selectedItem)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    static func create(viewController:UIViewController,title:String,isSetting:Bool,isHum: Bool=false, isAnother: Bool = false,escape: ((_ data: Int?) -> Void)?) {
        let vc = PickerViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.escape = escape
        vc.titleName = title
        vc.isSetting = isSetting
        vc.isHum = isHum
        vc.isAnother = isAnother
        viewController.present(vc, animated: true, completion: nil)
    }
    
    
}

extension PickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.init(name: Constant.Fonts.fontOne, size: 14)
            pickerLabel?.textAlignment = .center
        }
        if isAnother && row == 99 {
            pickerLabel?.text = "Infinite"
        } else {
            pickerLabel?.text = data[row]
        }
        pickerLabel?.textColor = UIColor.label
        
        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedItem = Int(data[row])!
    }
    
}
