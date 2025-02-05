//
//  CCTVViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/25/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import ONVIFCamera
import MobileVLCKit

class CCTVViewController: UIViewController, ConfigAdminRolles, VLCMediaPlayerDelegate {
    func adminChanged() {
        self.admin()
    }
    
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var playLabel: UILabel!
    
    var movieView: UIView!

    var equipment: Equipment?
    // The Onvif camera from the pod
    var camera: ONVIFCamera = ONVIFCamera(with: "XX", credential: nil) {
        didSet {
            self.ipLabel.text = "Connecting to: " + "\(cctv?.ip ?? "")"
            self.playLabel.text = "Initializing ..."
        }
    }
    var mediaPlayer: VLCMediaPlayer? = VLCMediaPlayer()

    var cctv: CCTVModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.ipLabel.text = ""
        self.playLabel.text = ""
        
        self.adminAccess()
        
        backBarButtonAttribute(color: .label, name: "")

        //Setup movieView
        self.movieView = UIView()
        self.movieView.backgroundColor = UIColor.clear
        self.movieView.frame = UIScreen.screens[0].bounds
        
        //Add movieView to view controller
        self.view.addSubview(self.movieView)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.6) { [weak self] in
            guard let self = self else { return }
            self.view.bringSubviewToFront(self.movieView)
            
            if let equipment = self.equipment, let name = equipment.name {
                self.title = name
                if let cctv = CCTVModel.cctvModels.last(where: { ctv in
                    return ctv.equipmentId == equipment.id && ctv.equipmentName == equipment.name
                }) {
                    self.cctv = cctv
                    self.ipLabel.text = "Connecting to: " + "\(cctv.ip)"
                    self.playLabel.alpha = 1
                    if cctv.ip.lowercased().hasPrefix("rtsp") && cctv.ip.count > 8 {
                        if !cctv.username.isEmpty, !cctv.password.isEmpty {
                            self.play(uri: self.createRTSPLink(ip: cctv.ip, username: cctv.username, password: cctv.password))
                        } else {
                            self.play(uri: cctv.ip)
                        }
                    } else {
                        self.start(cctv: cctv)
                    }
                } else {
                    self.ipLabel.text = ""
                    self.playLabel.alpha = 0
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mediaPlayer?.stop()
        mediaPlayer = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        if let equipment = self.equipment {
            let vc = ConnectCCTVViewController.create {[weak self] ip, username, password in
                guard let self = self else { return }
                let cctv = CCTVModel.init(ip: ip, username: username, password: password, equipmentId: equipment.id, equipmentName: equipment.name ?? "")
                self.cctv = cctv
                CCTVModel.add(cctv: cctv)
                if ip.lowercased().hasPrefix("rtsp") && ip.count > 8 {
                    var rtspIP = ip
                    
                    if !username.isEmpty, !password.isEmpty {
                        rtspIP = self.createRTSPLink(ip: ip, username: username, password: password)
                    } else {
                        rtspIP = ip
                    }
                    
                    self.play(uri: rtspIP)
                } else {
                    self.start(cctv: cctv)
                }
            }
            
            self.present(vc, animated: true)
        }
    }
    
    func createRTSPLink(ip: String, username: String, password: String) -> String {
        var rtspIP = ip
        let range = rtspIP.startIndex...rtspIP.index(rtspIP.startIndex, offsetBy: 6)
        rtspIP.removeSubrange(range)
        
        let uri = "rtsp://\(username):\(password)@" + String(rtspIP)

        return uri
    }
    
    func start(cctv: CCTVModel) {
        self.playLabel.alpha = 1
        self.playLabel.text = "No 🎥 connected"

        camera = ONVIFCamera(with: cctv.ip,
                             credential: (login: cctv.username, password: cctv.password),
                             soapLicenseKey: "69728270J9049954P") // "69728270J9049954P"
                  
        camera.getServices { (error) in
            
            if error == nil {
                self.getDeviceInformation()
            }
        }
    }
    
    private func getDeviceInformation() {
        camera.getCameraInformation(callback: { (camera) in
            self.cameraIsConnected()
        }, error: { (reason) in
            self.playLabel.text = reason
        })
    }
    
    func cameraIsConnected() {
        let info = "Getting profiles..."
        self.playLabel.text = info
        updateProfiles()
    }
    
    /// Once the camera credential and IP are valid, we retrieve the profiles and the streamURI
    private func updateProfiles() {
        if camera.state == .Connected {
            camera.getProfiles(profiles: {[weak self] (profiles) -> () in
                guard let self = self else { return }
                let title = self.camera.state == .HasProfiles ? "Getting streaming URI..." : "No Profiles... 😢"
                self.playLabel.text = title
                if let profiles = profiles, profiles.count > 0 {
                    // Retrieve the streamURI with the latest profile
                    self.camera.getStreamURI(with: profiles.first!.token, uri: { (uri) in
                        
                        print("URI: \(uri ?? "No URI Provided")")
                        
                        if let uri = uri {
                            self.play(uri: uri)
                        }
                    })
                }
            })
        }
    }
    
    func play(uri: String) {
        self.playLabel.alpha = 0
        self.playLabel.text = ""
        
        if let url = URL(string: uri) {
            let media = VLCMedia(url: url)
            
            self.mediaPlayer?.stop()
            self.mediaPlayer?.media = media
            self.mediaPlayer?.delegate = self
            self.mediaPlayer?.drawable = self.movieView
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
                guard let self = self else {return }
                
                self.ipLabel.text = "Playing Stream URI \(self.cctv?.ip ?? "")"
                self.mediaPlayer?.play()
            }
        }
    }
    
    deinit {
        mediaPlayer = nil
    }
}


struct CCTVModel: Codable {
    var id = UUID().uuidString
    let ip: String
    let username: String
    let password: String
    let equipmentId: Int64
    let equipmentName: String
    
    static public var archiveURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("ccv").appendingPathExtension("ccv")
    }
    
    static func encode(userInfo: [CCTVModel], directory dir: URL) {
        let propertyListEncoder = PropertyListEncoder()
        if let encodedProduct = try? propertyListEncoder.encode(userInfo) {
            try? encodedProduct.write(to: dir, options: .noFileProtection)
        }
    }
    
    static func decode(directory dir: URL) -> [CCTVModel]? {
        let propertyListDecoder = PropertyListDecoder()
        if let retrievedProductData = try? Data.init(contentsOf: dir), let decodedProduct = try? propertyListDecoder.decode([CCTVModel].self, from: retrievedProductData) {
            return decodedProduct
        }
        return nil
    }
    
    static var cctvModels: [CCTVModel] {
        get {
            CCTVModel.decode(directory: CCTVModel.archiveURL) ?? []
        }
        set {
            CCTVModel.encode(userInfo: newValue, directory: CCTVModel.archiveURL)
        }
    }
    
    static func deleteCCTVBy(id: String) {
        if let itemIndex = cctvModels.firstIndex(where: { $0.id == id }) {
            cctvModels.remove(at: itemIndex)
        }
    }
    
    static func add(cctv: CCTVModel) {
        cctvModels.append(cctv)
    }
}
