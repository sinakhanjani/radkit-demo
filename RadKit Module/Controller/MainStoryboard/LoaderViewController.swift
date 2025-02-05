//
//  ViewController.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import LocalAuthentication
import NetworkExtension

class LoaderViewController: UIViewController {

    @IBOutlet weak var loaderView: UIView!
    
    fileprivate let dispathGroup = DispatchGroup()

    var activityIndicatorView: NVActivityIndicatorView?
    private var isLogin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WebAPI.instance.startMonitoring()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.beginActivityIndicator()
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            if Password.shared.currentPassword != nil {
                self.authenticateWithTouchID { [weak self] ok in
                    guard let self = self else { return }
                    if ok {
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "toMainSegue", sender: nil)
                        }
                    }
                }
            } else {
                self.performSegue(withIdentifier: "toMainSegue", sender: nil)
            }
        }
    }
    
    func beginActivityIndicator() {
        let padding: CGFloat = 36.0
        
        let x = CGFloat(-4)
        let y = CGFloat(0)
        let frame = CGRect(x: x, y: y, width: padding, height: padding)
        activityIndicatorView = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.circleStrokeSpin, color: Constant.Colors.green, padding: padding)
        loaderView.addSubview(activityIndicatorView!)
        activityIndicatorView!.startAnimating()
    }
    
    func endActivityIndicator() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.0) { [weak self] in
            guard let self = self else { return }
            self.activityIndicatorView?.stopAnimating()
            self.removeAnimate()
        }
    }
    
    static func getNetworkInfo(compleationHandler: @escaping ([String: Any])->Void) {
       var currentWirelessInfo: [String: Any] = [:]
        
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                guard let network = network else {
                    compleationHandler([:])
                    return
                }
                
                let bssid = network.bssid
                let ssid = network.ssid
                currentWirelessInfo = ["BSSID ": bssid, "SSID": ssid, "SSIDDATA": "<54656e64 615f3443 38354430>"]
                compleationHandler(currentWirelessInfo)
            }
        }
    }


    @IBAction func unwindToLoaderViewController(_ segue: UIStoryboardSegue) {
        //
    }
}
