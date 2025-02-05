//
//  TimeZoneViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/8/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import DropDown

class TimeZoneViewController: UIViewController, NWSocketConnectionDelegate {
    func recievedItem(_ bytes: [UInt8]?, _ device: Device?, tag: Int, dict: Dictionary<String, Any>?) {
        // direct request
        if tag == 152 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard var data = bytes else { return }

                data.removeFirst()
                self.updateUI(data: data)
                self.dismiss(animated: true)
            }
        }
        // first attempted
        if tag == 153 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard var data = bytes else { return }

                data.removeFirst()
                self.updateUI(data: data)
            }
        }
    }
    private let deviceDropButton = DropDown()
    var selectedTimeZone: Double?
    var dataSource: [Double] {
        var items = [Double]()
        for i in -12...12 {
            items.append(Double(i))
            if i != 12 {
                items.append(Double(i)+(0.5))
            }
        }
        
        return items
    }
    
    private let dayDropButton = DropDown()
    var selectedDay: Int?
    var dayDataSource: [Int] {
        return [0,1,2,3,4,5,6]
    }
    var datTitles: [String] {
        return ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"]
    }
    var device: Device!
    
    @IBOutlet weak var dailySwitch: UISwitch!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timeZoneButton: RoundedButton!
    @IBOutlet weak var dayButton: RoundedButton!
    @IBOutlet weak var boxView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NWSocketConnection.instance.delegate = self
        //
        let touch = UITapGestureRecognizer(target: self
            , action: #selector(tapped))
        bgView.addGestureRecognizer(touch)
        // day
        dayDropButton.dataSource = datTitles.map({ item in
            return "\(item)"
        })
        dayDropButton.anchorView = dayButton
        dayDropButton.bottomOffset = CGPoint(x: 0, y: dayButton.bounds.height)
        dayDropButton.textFont = UIFont.persianFont(size: 14.0)
        self.dayDropButton.selectionAction = {[weak self] (index, item) in
            guard let self = self else { return }
            self.dayButton.setTitle("\(self.datTitles[index])", for: .normal)
            self.selectedDay = self.dayDataSource[index]
        }
        // Do any additional setup after loading the view.
        deviceDropButton.dataSource = dataSource.map({ item in
            let byte1 = item
            var b1 = ""
            
            if Int(byte1*2) % 2 == 0 {
                b1 = "\(Int(byte1)):00"
                if byte1 >= 0 {
                    b1 = "GMT+\(b1)"
                } else {
                    b1 = "GMT\(b1)"
                }
            } else {
                if byte1 >= 0 {
                    b1 = "GMT+\(Int(byte1)):30"
                } else {
                    b1 = "GMT\(Int(byte1)):30"
                }
            }
            
            return b1
        })
        deviceDropButton.anchorView = timeZoneButton
        deviceDropButton.bottomOffset = CGPoint(x: 0, y: timeZoneButton.bounds.height)
        deviceDropButton.textFont = UIFont.persianFont(size: 14.0)
        
        self.deviceDropButton.selectionAction = {[weak self] (index, item) in
            guard let self = self else { return }
            self.timeZoneButton.setTitle(item, for: .normal)
            self.selectedTimeZone = self.dataSource[index]
        }
        // first call
        self.boxView.backgroundColor = Constant.Colors.blue
        NWSocketConnection.instance.send(tag:153, device: self.device, typeRequest: .updateTime, data: [UInt8(60),UInt8(60),UInt8(60),UInt8(60),UInt8(60),UInt8(60)]) { [weak self] (data, device) in
            /////
        }
        self.dayButton.setTitle("--", for: .normal)
        self.bgView.backgroundColor = .darkGray
    }
    
    func createData() -> [UInt8]? {
        if let selectedTimeZone = selectedTimeZone, let selectedDay = selectedDay {
            let byte1 = UInt8(bitPattern: Int8(Int(selectedTimeZone * 4)))
            let byte2 = UInt8(self.dailySwitch.isOn ? 1:0)
            let byte3 = UInt8(selectedDay)//dateFormatter(format: "dd")
            let byte4 = dateFormatter(format: "HH")
            let byte5 = dateFormatter(format: "mm")
            let byte6 = UInt8(0)//dateFormatter(format: "ss")
            
            return [byte1,byte2,byte3,byte4,byte5,byte6]
        }
        
        return nil
    }
    
    func updateUI(data: [UInt8]) {
        self.boxView.backgroundColor = .systemBackground
        //0
        let byte1 = (Double(Int8(bitPattern: data[0]))/4)
        var b1 = ""
        if Int(byte1*2) % 2 == 0 {
            b1 = "\(Int(byte1)):00"
            if byte1 >= 0 {
                b1 = "GMT+\(b1)"
            } else {
                b1 = "GMT\(b1)"
            }
        } else {
            if byte1 >= 0 {
                b1 = "GMT+\(Int(byte1)):30"
            } else {
                b1 = "GMT\(Int(byte1)):30"
            }
        }
        self.timeZoneButton.setTitle(b1, for: .normal)
        self.selectedTimeZone = Double(Int8(bitPattern: data[0]))/4
        //1
        self.dailySwitch.isOn = data[1] == UInt8(0) ? false: true
        //2
        self.selectedDay = Int(data[2])
        self.dayButton.setTitle("\(self.datTitles[Int(data[2])])", for: .normal)
        //3
        var hour = ""
        if Int(data[3]) < 10 {
            hour = "0\(Int(data[3]))"
        } else {
            hour = "\(Int(data[3]))"
        }
        //4
        var minute = ""
        if Int(data[4]) < 10 {
            minute = "0\(Int(data[4]))"
        } else {
            minute = "\(Int(data[4]))"
        }
        //5
        var sec = ""
        if Int(data[5]) < 10 {
            sec = "0\(Int(data[5]))"
        } else {
            sec = "\(Int(data[5]))"
        }
        
        if let date = convertToDate(strDate: "\(hour)-\(minute)-\(sec)") {
            self.datePicker.date = date
        }
    }
    
    func directRequest() {
        if let sendData = createData() {
            boxView.backgroundColor = Constant.Colors.blue
            NWSocketConnection.instance.send(tag:152, device: self.device, typeRequest: .updateTime, data: sendData) { [weak self] (data, device) in
                /////
            }
        } else {
            self.presentIOSAlertWarning(message: "Please select the all parameters.", completion: {})
        }
    }
    
    func convertToDate(strDate: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = "HH-mm-ss"
        return df.date(from: strDate)
    }
    
    func dateFormatter(format: String) -> UInt8 {
        let df = DateFormatter()
        df.dateFormat = format
        
        return UInt8(Int(df.string(from: datePicker.date))!)
    }

    @objc func tapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        self.directRequest()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func selectDayButtonTapped(_ sender: Any) {
        dayDropButton.show()
    }
    @IBAction func selectDeviceButtonTapped(_ sender: Any) {
        deviceDropButton.show()
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
    }
    
    static func create(device: Device) -> TimeZoneViewController {
        let vc = TimeZoneViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.device = device
        return vc
    }
}
