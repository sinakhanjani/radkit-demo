//
//  ModuleInputViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 11/10/1399 AP.
//  Copyright © 1399 AP Sina Khanjani. All rights reserved.
//

import UIKit

class ModuleInputViewController: UIViewController {
    
    struct SelectedItem {
        let channel: Double
        let name: String
        let row: Int
    }
    
    enum DataType {
        case remote([Int])
        case external([Int])
        case input([Int])
        
        var data: [Int] {
            switch self {
            case .remote(let x):
                return x
            case .external(let x):
                return x
            case .input(let x):
                return x
            }
        }
    }
    
    var externalData: DataType {
        if isSwitch {
            return .external([1,2,3,4])
        } else {
            return .external([1,2,3,4])
        }
    }
    var inputData: DataType {
        if isSwitch {
            return .input([5,6,7,8,9,10,11,12,13,14,15,16])
        } else {
            return .input([])
        }
    }
    var remoteData: DataType {
        if isSwitch {
            return .remote([17,18,19,20,21,22,23,24,25,26,27,28])
        } else {
            return .remote([5,6,7,8,9,10])
        }
    }
    
    var categoryType: [String] {
        if isSwitch {
            return ["Remote", "External Scenario", "Input"]
        } else {
            return ["Remote", "External Scenario"]
        }
    }
    var dataType: DataType!
    var isSwitch: Bool = true
    
    private var selectedItem: SelectedItem = SelectedItem(channel: 1, name: "External", row: 1)
    
    private var completion: ((_ selectedItem: SelectedItem?) -> Void)?
    
    @IBOutlet weak var typePickerView: UIPickerView!
    @IBOutlet weak var channelPickerView: UIPickerView!
    @IBOutlet weak var bgView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataType = externalData
        typePickerView.selectRow(1, inComponent: 0, animated: false)
        
        let touch = UITapGestureRecognizer(target: self
            , action: #selector(tapped))
        bgView.addGestureRecognizer(touch)
    }
    
    @objc func tapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        self.completion?(selectedItem)
        print(selectedItem)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    static func create(completion: ((_ selectedItem: SelectedItem?) -> Void)?) -> ModuleInputViewController {
        let vc = ModuleInputViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        
        return vc
    }
}

extension ModuleInputViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return categoryType.count
        } else {
            return dataType.data.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)

        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.init(name: Constant.Fonts.fontOne, size: 14)
            pickerLabel?.textAlignment = .center
            pickerLabel?.textColor = UIColor.label
        }

        if pickerView.tag == 0 {
            let item = categoryType[row]
            pickerLabel?.text = item
        } else {
            pickerLabel?.text = "\(row + 1)"
        }
        
        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            switch row {
            case 0:
                self.dataType = .remote(self.remoteData.data)
            case 1:
                self.dataType = .external(self.externalData.data)
            case 2:
                self.dataType = .input(self.inputData.data)
            default:
                return
            }
            self.channelPickerView.reloadAllComponents()
            self.channelPickerView.selectRow(0, inComponent: component, animated: false)
            
            var name: String = ""
            var channel: Double = 0
            switch row {
            case 0:
                name = "remote"
                channel = 17
            case 1:
                name = "External"
                channel = 1
            case 2:
                name = "Input"
                channel = 5
            default:
                break
            }
            self.selectedItem = SelectedItem(channel: channel, name: name, row: 1)
        } else {
            let item = dataType.data[row]
            var name: String
            switch dataType {
            case .external:
                name = "External"
            case .input:
                name = "Input"
            case .remote:
                name = "remote"
            default:
                name = ""
            }
            self.selectedItem = SelectedItem(channel: Double(item), name: name, row: row + 1)
        }
    }
}
