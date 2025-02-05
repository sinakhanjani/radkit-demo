//
//  TimeViewController.swift
//  Master
//
//  Created by Sina khanjani on 11/15/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

class TimeViewController: UIViewController {
    
    enum Type1 {
        case channel
        case time
    }
    
    enum Sina {
        case ss(String)
    }
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    private var selectedTime: Double? = 0.5
    private var completion: ((_ selectedTime: Double?) -> Void)?
    private var type : Type1 = .time
    private var selectedChannel: Int = 1
    public var channels = [1,2,3,4]
    private var data: [Double] {
        var begin:Double = 0.0
        var times = [Double]()
        for _ in 0..<40 {
            begin += 0.5
            times.append(begin)
        }
        for _ in 0..<39 {
            begin += 1.0
            times.append(begin)
        }
        times.append(60.0)
        times.append(120.0)
        times.append(180.0)
        times.append(240.0)
        times.append(300.0)
        
        //new
        times.append(600.0)
        times.append(15*60.0)
        times.append(20*60.0)
        times.append(30*60.0)
        times.append(40*60.0)
        times.append(50*60.0)
        times.append(60*60.0)

        return times
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let touch = UITapGestureRecognizer(target: self
            , action: #selector(tapped))
        self.bgView.addGestureRecognizer(touch)
        if type == .time {
            self.titleLabel.text = "Select Time"
            if let _ = self.selectedTime {
//                self.selectedTime = lastTime
                // set picket to this time *
            } else {
                //
            }
        } else {
            self.titleLabel.text = "Channel Selection"
            //
        }
    }
    
    @objc func tapped() {
        self.dismiss(animated: true, completion: nil)
    }

    static func create(lastTime:Double?,type:Type1,completion: ((_ selectedTime: Double?) -> Void)?) -> TimeViewController {
        let vc = TimeViewController()
        vc.completion = completion
//        vc.selectedTime = lastTime
        vc.type = type
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
    
    @IBAction func agreeButtonTapped(_ sender: UIButton) {
        if type == .time {
            self.completion?(self.selectedTime)
        } else {
            self.completion?(Double(self.selectedChannel))
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}


extension TimeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if type == .time {
            return data.count
        } else {
            return channels.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.init(name: Constant.Fonts.fontOne, size: 14)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.textColor = UIColor.label
        if type == .time {
            let time = data[row]
            if time >= 0.5 && time <= 20 {
                pickerLabel?.text = "\(data[row]) Second"
            }
            if time >= 21.0 && time <= 59 {
                pickerLabel?.text = "\(Int(data[row])) Second"
            }
            if time >= 60.0 && time <= 300.0 {
                let minute = time/60.0
                pickerLabel?.text = "\(Int(minute)) Minutes"
            }
            if time >= 600.0 && time <= (50*60.0) {
                let minute = time/60.0
                pickerLabel?.text = "\(Int(minute)) Minutes"
            }
            if time == (3600.0) {
                pickerLabel?.text = "1 Hour"
            }
        } else {
            pickerLabel?.text = "Channel" + " " + "\(channels[row])"
        }
        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if type == .time {
            self.selectedTime = data[row]
        } else {
            self.selectedChannel = channels[row]
        }
    }
    
}
