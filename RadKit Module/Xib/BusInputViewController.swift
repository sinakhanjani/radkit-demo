
import UIKit
import DropDown

class BusInputViewController: UIViewController {
    
    struct SelectedItem {
        let channel: Double
        let name: String
        let row: Int
    }
    
    enum DataType {
        case remote([Int])
        case external([Int])
        case input([Int])
        case Channel([Int])
        
        var data: [Int] {
            switch self {
            case .remote(let x):
                return x
            case .external(let x):
                return x
            case .input(let x):
                return x
            case .Channel(let x):
                return x
            }
        }
    }
    
    var externalData: DataType {
        if isSwitch {
            if isRemotes {
                return .Channel([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
            } else {
                return .external([1,2,3,4])
            }
        } else {
            if isRemotes {
                return .Channel([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
            } else {
                return .external([1,2,3,4])
            }
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
    
    var channelData: DataType {
        return .Channel([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
    }
    
    var categoryType: [String] {
        if isSwitch {
            return ["Remote", "External Scenario", "Input"]
        } else {
            if isRemotes {
                return ["Channel"]
            } else {
                return ["Remote", "External Scenario"]
            }
        }
    }
    var dataType: DataType!
    var isSwitch: Bool = true
    var isRemotes: Bool = false
    
    private var selectedItem: SelectedItem = SelectedItem(channel: 1, name: "External", row: 1)
    
    private var completion: ((_ selectedItem: SelectedItem?,_ device: Device?) -> Void)?
    
    private let deviceDropButton = DropDown()
    var selectedDevice: Device?
    var dataSource = [Device]()
    
    @IBOutlet weak var typePickerView: UIPickerView!
    @IBOutlet weak var channelPickerView: UIPickerView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var deviceButton: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let devices = CoreDataStack.shared.devices?.filter({ item in
            print(item.version, item.type)
            return (Int(item.version) >= 15) //&& (Int(item.type) < 50) && !item.isBossDevice
        }).uniqued() {
            self.dataSource = devices
            if let device = devices.first {
                if let devType = DeviceType.init(rawValue: Int(device.type)) {
                    var serial = "\(device.serial)"
                    if serial.count < 6 {
                        while serial.count < 6 {
                            serial = "0" + serial
                        }
                    }
                    
                    self.deviceButton.setTitle(devType.changed() + "\(serial)", for: .normal)
                    self.selectedDevice = device
                    switch devType {
                    case .rgbController,.thermostat,.dimmer:
                        self.isSwitch = false
                        self.isRemotes = false
                        break
                    case .tv,.remotes,.wifi:
                        self.isSwitch = false
                        self.isRemotes = true
                         break
                    case .switch12_0,.switch12_1,.switch12_2,.switch12_3, .switch12_sim_0:
                        self.isSwitch = true
                        self.isRemotes = false
                        break
                    default:
                        break
                    }
                }
            }
        }
        
        deviceDropButton.dataSource = dataSource.map { item in
            if let devType = DeviceType.init(rawValue: Int(item.type)) {
                var serial = "\(item.serial)"
                if serial.count < 6 {
                    while serial.count < 6 {
                        serial = "0" + serial
                    }
                }
                
                return devType.changed() + "\(serial)"
            }
            return ""
        }
        deviceDropButton.anchorView = deviceButton
        deviceDropButton.bottomOffset = CGPoint(x: 0, y: deviceButton.bounds.height)
        deviceDropButton.textFont = UIFont.persianFont(size: 14.0)
        
        self.deviceDropButton.selectionAction = {[weak self] (index, item) in
            guard let self = self else { return }
            self.deviceButton.setTitle(item, for: .normal)
            self.selectedDevice = self.dataSource[index]
            let type = DeviceType.init(rawValue: Int(self.dataSource[index].type))!
            
            switch type {
            case .rgbController,.thermostat,.dimmer:
                self.isSwitch = false
                self.isRemotes = false
                break
            case .tv,.remotes,.wifi:
                self.isSwitch = false
                self.isRemotes = true
                 break
            case .switch12_0,.switch12_1,.switch12_2,.switch12_3, .switch12_sim_0:
                self.isSwitch = true
                self.isRemotes = false
                break
            default:
                break
            }
            
            self.dataType = self.externalData
            self.channelPickerView.reloadAllComponents()
            self.typePickerView.reloadAllComponents()
            self.typePickerView.selectRow(1, inComponent: 0, animated: false)
        }

        //////////
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
        if let selectedDevice = selectedDevice {
            self.completion?(selectedItem, selectedDevice)
            print(selectedItem)
        } else {
            self.presentIOSAlertWarning(message: "Please select a device", completion: {})
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func selectDeviceButtonTapped(_ sender: Any) {
        deviceDropButton.show()
    }
    
    static func create(completion: ((_ selectedItem: SelectedItem?,_ device: Device?) -> Void)?) -> BusInputViewController {
        let vc = BusInputViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.completion = completion
        
        return vc
    }
}

extension BusInputViewController: UIPickerViewDataSource, UIPickerViewDelegate {
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
                if self.isRemotes {
                    self.dataType = .Channel(self.channelData.data)
                } else {
                    self.dataType = .remote(self.remoteData.data)
                }
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
                if isRemotes {
                    name = "channel"
                    channel = 1
                } else {
                    name = "Remote"
                    channel = 17
                }
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
                if isRemotes {
                    name = "Channel"
                } else {
                    name = "Remote"
                }
            default:
                name = ""
            }
            self.selectedItem = SelectedItem(channel: Double(item), name: name, row: row + 1)
        }
    }
}
