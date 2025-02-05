
//
//  EspTouchViewController.swift
//  Master
//
//  Created by Sina khanjani on 6/3/1398 AP.
//  Copyright © 1398 iPersianDeveloper. All rights reserved.
//

import UIKit
import Lottie
import SwiftMQTT
import CoreLocation

protocol EspTouchViewControllerDelegate: AnyObject {
    func completeEspTouchResults()
}

class EspTouchViewController: UIViewController, ESPTouchDelegate,UITextFieldDelegate,CLLocationManagerDelegate {
    
    @IBOutlet weak var serialScanTextField: UITextField!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var espTouchButton: RoundedButton!
    @IBOutlet weak var lottieView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var localWifiNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var SSIDButton: RoundedButton!
    @IBOutlet weak var simcardView: UIView!
    @IBOutlet weak var espView: UIView!
    
    var locationManager: CLLocationManager!
    
    private var mqtt:MQTTSession?
    private let vc = IndicatorViewController.create { (_) in
        
    }
    private let port = 22199
    private let mqttURL = "s1.imaxbms.com"
    private var decodeItem: (deviceType: Int, username: Int, password: Int, serial: Int)?
    private var version: Int?
    private var simcardToken: String? {
        willSet {
            if let internetToken = newValue, internetToken != simcardToken , let decode = decodeItem {
                CoreDataStack.shared.addRadkitModule(internetToken: internetToken, localToken: "", username: "\(decode.username)", password: "\(decode.password)", port: port, serial: decode.serial, type: decode.deviceType, url: mqttURL, version: version ?? 1, ip: "", wifibssid: "NOT") { [weak self] _,_ in
                    
                    CoreDataStack.shared.saveContext()
                    CoreDataStack.shared.fetchDatabase()
                    
                    if let devices = CoreDataStack.shared.devices {
                        if let currentDevice = devices.first(where: { device in
                            device.serial == decode.serial
                        }) {
                            let connection = NWSocketConnection.instance.startConnection(device: currentDevice)
                            NWSocketConnection.deviceConnections.append(connection)
                            self?.vc.dismiss(animated: false) { [weak self] in
                                DispatchQueue.main.asyncAfter(deadline: .now()+0.4) { [weak self] in
                                    self?.dismiss(animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private let phoneFormat: [Character] = ["X", "X","X", "X", " ", "X", "X", "X", "X", " ", "X", "X", "X", "X", " ", "X", "X", "X", "X", " ", "X", "X", "X", "X"]
    
    var results : Array<ESPTouchResult> = Array()
    var esptouchTask : ESPTouchTask?
    var messageResult = ""
    var resultExpected = 0
    var boatAnimation: AnimationView!
    var statusTimming: Timer?
    var mqttCancelTimer: Timer?
    
    var currentValueTime:Float = 0
    var currentMQTTCanceTime:Float = 0
    
    weak var delegate:EspTouchViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        
        DispatchQueue.main.async {
            if (CLLocationManager.locationServicesEnabled()) {
                if #available(iOS 14.0, *) {
                    switch self.locationManager.authorizationStatus {
                    case .notDetermined, .restricted, .denied:
//                            DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in
//                                self?.presentIOSAlertWarning(message: "Please enable GPS access for the Radkit app") {
//                                    UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
//                                }
//                            }
                        print("No access")
                    case .authorizedAlways, .authorizedWhenInUse:
                        print("Access")
                    @unknown default:
                        break
                    }
                }
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            } else {
//                    DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in
//                        self?.presentIOSAlertWarning(message: "Please enable GPS access for the Radkit app") {
//                            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
//                        }
//                    }
            }
        }
        if let locationManager = self.locationManager {
            locationManager.requestWhenInUseAuthorization()
        }
        
        passwordTextField.delegate = self
        view.dismissedKeyboardByTouch()
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        EspTouchManager.shared.configureEspTouch()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("didChangeAuthorization ", status)
        switch status {
        case .restricted, .denied, .notDetermined:
            DispatchQueue.main.async {
                if !CLLocationManager.locationServicesEnabled() {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in
                        self?.presentIOSAlertWarningWithTwoButton(message: "Enable the location permission to get the WI-FI name automatically", buttonOneTitle: "Cancel", buttonTwoTitle: "OK", handlerButtonOne: {
                            // do nothing
                        }, handlerButtonTwo: {
                            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)

                        })
                    }
                }
            }
            if #available(iOS 14.0, *) {
                switch status {
                case .notDetermined, .restricted, .denied:
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in
                        self?.presentIOSAlertWarningWithTwoButton(message: "Enable the location permission to get the WI-FI name automatically", buttonOneTitle: "Cancel", buttonTwoTitle: "OK", handlerButtonOne: {
                            // do nothing
                        }, handlerButtonTwo: {
                            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)

                        })
                    }
                default:
                    break
                }
            }
        case .authorizedWhenInUse, .authorized, .authorizedAlways:
            LoaderViewController.getNetworkInfo { [weak self] dict in
                guard let self = self else { return }
                if let ssid = dict["SSID"] as? String {
                    EspTouchManager.shared.espTouch_ssid = ssid
                    self.updateSSIDUI(ssid:ssid)
                }
                if let bssid = dict["BSSID"] as? String {
                    EspTouchManager.shared.espTouch_bssid = bssid
                }
            }
        @unknown default:
            break
        }
    }
    
    private func formatPhone(_ number: String) -> String {
        let cleanNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        var result = ""
        var index = cleanNumber.startIndex
        for ch in phoneFormat {
            if index == cleanNumber.endIndex {
                break
            }
            if ch == "X" {
                result.append(cleanNumber[index])
                index = cleanNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        
        return result
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func updateUI() {
        serialScanTextField.keyboardType = .asciiCapableNumberPad
        lottieConfiguration()
        progressView.alpha = 0.0
        updateSSIDUI(ssid: EspTouchManager.shared.espTouch_ssid)
        LoaderViewController.getNetworkInfo { [weak self] dict in
            if let ssid = dict["SSID"] as? String {
                self?.updateSSIDUI(ssid: ssid)
            }
        }
    }
    
    func updateSSIDUI(ssid: String) {
        self.localWifiNameLabel.text = ssid
        if WebAPI.instance.reachability.connection == .wifi {
            if (ssid == "") || ssid == "SSID" {
                SSIDButton.isHidden = false
            } else {
                SSIDButton.isHidden = true
            }
        } else if  WebAPI.instance.reachability.connection == .cellular || WebAPI.instance.reachability.connection == .none {
            SSIDButton.isHidden = true
        }
    }
    
    func lottieConfiguration() {
        boatAnimation = AnimationView(name: "lottie_splash")
        // Set view to full screen, aspectFill
        boatAnimation.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        boatAnimation.contentMode = .scaleAspectFill
        boatAnimation.frame = lottieView.bounds
        // Add the Animation
        lottieView.addSubview(boatAnimation)
        boatAnimation.loopMode = .loop
    }
    
    func onEsptouchResultAdded(with result: ESPTouchResult!) {
        results.append(result)
        DispatchQueue.main.async { [ weak self] in
            guard let self = self else { return }
            if(self.results.count == self.resultExpected) {
                self.esptouchTask?.interrupt()
            }
            print("\(self.messageResult)\(result.bssid!) - ip: \(ESP_NetUtil.descriptionInetAddr4(by: result.ipAddrData)!)\n")
        }
    }
    
    func sendSmartConfig() {
        // d8:fe:e3:a9:9:da
        view.endEditing(true)
        results.removeAll()
        statusTimming = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            let maxTime:Float = 40
            if self.currentValueTime <= maxTime {
                let percent = (Float(self.currentValueTime)/maxTime)*100
                self.progressView.setProgress(percent/100, animated: true)
                self.currentValueTime += 1
            } else {
                self.finishedESPTouch()
                self.currentValueTime = 0
                self.statusTimming?.invalidate()
            }
        })
        print(EspTouchManager.shared.espTouch_ssid, EspTouchManager.shared.espTouch_bssid, self.passwordTextField.text!)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in //.global() //userInitiated
            guard let self = self else { return }
            self.esptouchTask = ESPTouchTask.init(apSsid: EspTouchManager.shared.espTouch_ssid, andApBssid: EspTouchManager.shared.espTouch_bssid, andApPwd: self.passwordTextField.text!)
            if let task = self.esptouchTask {
                task.setEsptouchDelegate(self)
                print(Int32.max)
                let  results: NSArray = (task.execute(forResults: Int32(self.resultExpected == 0 ?  Int(Int32.max) : self.resultExpected))! as NSArray)
                print(results)
            }
        }
    }
    
    private func finishedESPTouch() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.boatAnimation.stop()
            self.statusTimming?.invalidate()
            self.espTouchButton.isEnabled = true
            self.progressView.alpha = 0.0
            self.delegate?.completeEspTouchResults()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func segmentControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            view.endEditing(true)
            self.espView.alpha = 1
            self.simcardView.alpha = 0
            self.serialScanTextField.text = ""
        default:
            self.espView.alpha = 0
            self.simcardView.alpha = 1
            self.serialScanTextField.becomeFirstResponder()
            break
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        guard !passwordTextField.text!.isEmpty else {
            self.presentIOSAlertWarning(message:"Please enter the modem password") {
                //
            }
            return
        }
        guard  WebAPI.instance.reachability.connection == .wifi else {
            self.presentIOSAlertWarning(message: "Please connect to the WIFI network!") {
                //
            }
            return
        }
        self.espTouchButton.isEnabled = false
        progressView.alpha = 1.0
        self.boatAnimation.play()
        sendSmartConfig()
    }
    
    @IBAction func enterWifiSSIDButtonTapped(_ sender: Any) {
        self.presentAlertActionWithTextField(message: "", title: "WiFi Name", textFieldPlaceHolder: "Enter WiFi name") { [weak self] name in
            guard let self = self else { return }
            self.localWifiNameLabel.text = name
            EspTouchManager.shared.espTouch_ssid = name
        }
    }
    
    @IBAction func phoneNumberValueChanged(sender: InsetTextField) {
        sender.text = formatPhone(sender.text!)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        esptouchTask?.interrupt()
        self.statusTimming?.invalidate()
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func qrScanButtonTapped(_ sender: Any) {
        let vc = QRScannerViewController.create()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func qrAgreeButtonTapped(_ sender: Any) {
        let code = serialScanTextField.text!.replacingOccurrences(of: " ", with: "")
        guard code.count == 20 else {
            self.presentIOSAlertWarning(message:"Please enter the serial correctly", completion: {})
            return
        }
        let decode = decodeQR(code: code)
        self.decodeItem = decode
        guard let decode = decode else { return }
        let host = mqttURL
        let port = UInt16(port)
        let clientID = self.clientID()
        let mqttSession = MQTTSession(host: host, port: port, clientID: clientID, cleanSession: true, keepAlive: 10, useSSL: true)
        mqttSession.delegate = self
        mqttSession.username = "\(decode.username)"
        mqttSession.password = "\(decode.password)"
        
        self.mqtt = mqttSession
        self.present(vc, animated: true, completion: nil)
        mqttSession.connect { [weak self] error in
            guard let self = self else { return }
            if error == .none {
                print("mqtt simcard is conntected to device serial : \(decode.serial)")
                self.mqttCancelTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
                    guard let self = self else { return }
                    if self.currentMQTTCanceTime >= 5 {
                        self.vc.dismiss(animated: true, completion: nil)
                        self.mqtt?.disconnect()
                        self.mqtt = nil
                        self.currentMQTTCanceTime = 0
                        self.mqttCancelTimer?.invalidate()
                        self.mqttCancelTimer = nil
                        return
                    }
                    self.currentMQTTCanceTime += 1
                })
                // send data to topic
                let publishTopic = "\(decode.serial)/sys"
                let subscribeTopic = "\(decode.serial)/app"
                var send: [UInt8] = Array("gscode".utf8)
                let nsdata = NSData(bytes: &send, length: send.count)
                let sendData = Data.init(referencing: nsdata)
                
                self.mqtt?.publish(sendData, in: publishTopic, delivering: .atMostOnce, retain: false) { [weak self] error in
                    guard let self = self else { return }
                    if error == .none {
                        print("simcard data published")
                    } else {
                        self.vc.dismiss(animated: true, completion: nil)
                    }
                }
                self.mqtt?.subscribe(to: subscribeTopic, delivering: .atMostOnce, completion: { [weak self] (error) in
                    guard let self = self else { return }
                    if error == .none {
                        print("simcard data subscribe topic")
                    } else {
                        self.vc.dismiss(animated: true, completion: nil)
                    }
                })
            } else {
                self.vc.dismiss(animated: true, completion: nil)
                print("mqtt cannot be connected to device simcard serial : \(decode.serial)")
            }
        }
    }
    
    static func create() -> EspTouchViewController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: String(describing: self)) as! EspTouchViewController
        return vc
    }
    
    deinit {
        print("ESPTOUCH VC Deinit")
    }
}

extension EspTouchViewController: MQTTSessionDelegate {
    func mqttDidReceive(message: MQTTMessage, from session: MQTTSession) {
        let bytes = message.payload.bytes //sample: [89, 74, 72, 80, 71, 80]
        if let token = toString(data: bytes) {
            if token.hasPrefix("B") {
                let scan = token.scan(components: token, split: ":")
                print("SIMCARD BOSS", scan)
                let bosDeviceCount = Int(scan[1])!
                let internetToken = scan[2]
                let version = Int(scan[3])
                
                var bossDevices = Array(scan[4...])
                var bossDeviceItems: [[String]] = []
                
                for _ in 0..<bosDeviceCount {
                    var arr = [String]()
                    arr.append(bossDevices[0])
                    arr.append(bossDevices[1])
                    arr.append(bossDevices[2])
                    
                    bossDevices.removeFirst()
                    bossDevices.removeFirst()
                    bossDevices.removeFirst()
                    
                    bossDeviceItems.append(arr)
                }
                
                bossDeviceItems.forEach { item in
                    if let decode = decodeItem {
                        CoreDataStack.shared.addRadkitModule(internetToken: "", localToken: "", username: "", password: "", port: 0, serial: Int(item[1])!, type: Int(item[0])!-50, url: "", version: Int(item[2])!,ip: "", wifibssid: EspTouchManager.shared.espTouch_bssid, isBossDevice: true, bridgeDeviceSerial: decode.serial, escape: nil)
                    }
                }
                
                self.version = version
                self.simcardToken = internetToken
            } else {
                self.simcardToken = token
                print("SIMCARD RECIEVED TOKEN",bytes, token)
            }
        }
        
        self.mqtt?.disconnect()
        self.mqtt = nil
    }
    
    func mqttDidAcknowledgePing(from session: MQTTSession) {
        //
    }
    
    func mqttDidDisconnect(session: MQTTSession, error: MQTTSessionError) {
        print("mqtt disconnected from username : \(session.username!)")
    }
    
    private func clientID() -> String {
        let userDefaults = UserDefaults.standard
        let clientIDPersistenceKey = "clientID\(arc4random())\(arc4random())"
        let clientID: String
        
        if let savedClientID = userDefaults.object(forKey: clientIDPersistenceKey) as? String {
            clientID = savedClientID
        } else {
            clientID = randomStringWithLength(5)
            userDefaults.set(clientID, forKey: clientIDPersistenceKey)
            userDefaults.synchronize()
        }
        
        return clientID
    }
    
    private func randomStringWithLength(_ len: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = String()
        for _ in 0..<len {
            let length = UInt32(letters.count)
            let rand = arc4random_uniform(length)
            let index = String.Index(encodedOffset: Int(rand))
            randomString += String(letters[index])
        }
        
        return String(randomString)
    }
    
    public func toString(data:[UInt8]) -> String? {
        var inputBytes: [UInt8] = data
        let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
        let data = Data.init(referencing: nsdata)
        if let str = String.init(data: data, encoding: .utf8) {
            return str
        } else {
            var bytes = data
            
            let crcHByte = bytes.removeLast() // 194
            let crcLByte = bytes.removeLast() // 90
            let unint16 = UInt16(crcLByte) << 8 | UInt16(crcHByte)
            
            let crc16ccitt = Data(bytes).crc16ccitt_xmodem()
            
            if unint16 == crc16ccitt {
                if let utf8StringCRC = String.init(bytes: bytes, encoding: .utf8) {
                    return utf8StringCRC
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
}

extension EspTouchViewController: QRScannerViewControllerDelegate {
    func qrScannerDidFind(code: String) {
        self.serialScanTextField.text = formatPhone(code)
        view.endEditing(true)
    }
}

extension EspTouchViewController {
    func decodeQR(code: String) -> (deviceType: Int, username: Int, password: Int, serial: Int)? {
        if Double(code) != nil {
            var codeArray = code.map { Int($0.description)! }
            let deviceType = Int("\(codeArray[0])\(codeArray[1])")!
            
            codeArray.removeFirst()
            codeArray.removeFirst()
            
            var uspItem: [Int] = []
            var uspArrayItem: [[Int]] = []
            
            for (index, code) in codeArray.enumerated() {
                let i = index+1
                uspItem.append(code)
                if i%3 == 0 {
                    uspArrayItem.append(uspItem)
                    uspItem = []
                }
            }
            
            let username = "\(uspArrayItem[0][0])\(uspArrayItem[1][0])\(uspArrayItem[2][0])\(uspArrayItem[3][0])\(uspArrayItem[4][0])\(uspArrayItem[5][0])"
            let password = "\(uspArrayItem[0][2])\(uspArrayItem[1][2])\(uspArrayItem[2][2])\(uspArrayItem[3][2])\(uspArrayItem[4][2])\(uspArrayItem[5][2])"
            let serial = "\(uspArrayItem[0][1])\(uspArrayItem[1][1])\(uspArrayItem[2][1])\(uspArrayItem[3][1])\(uspArrayItem[4][1])\(uspArrayItem[5][1])"
            
            return (deviceType: deviceType, username: Int(username)!, password: Int(password)!, serial: Int(serial)!)
        }
        
        return nil
    }
}
// 1281 1355 2143 8290 7947
