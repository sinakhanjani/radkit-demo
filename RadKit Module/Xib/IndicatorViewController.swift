//
//  IndicatorViewController.swift
//  Bisim App
//
//  Created by Sinakhanjani on 8/5/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
////
//
//import UIKit
//import NVActivityIndicatorView
//
//class IndicatorViewController: UIViewController {
//
//    @IBOutlet weak var bgView: UIView!
//    
//    var activityIndicatorView: NVActivityIndicatorView?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        updateUI()
//    }
//    
//    // Objc
//    @objc func dismissIndicatorViewController() {
//        self.endActivityIndicator()
//    }
//    
//    // Method
//    func updateUI() {
//        NotificationCenter.default.addObserver(self, selector: #selector(dismissIndicatorViewController), name: Constant.Notify.dismissIndicatorViewControllerNotify, object: nil)
//        self.showAnimate()
//        beginActivityIndicator()
//    }
//    
//    func beginActivityIndicator() {
//        let padding: CGFloat = 37.0
//        
//        let x = (UIScreen.main.bounds.width / 2) - (padding / 2)
//        let y = (UIScreen.main.bounds.height / 2) - (padding / 2)
//        let frame = CGRect(x: x, y: y, width: padding, height: padding)
//        activityIndicatorView = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.circleStrokeSpin, color: .darkGray, padding: padding)
//        self.view.addSubview(activityIndicatorView!)
//        activityIndicatorView!.startAnimating()
//    }
//    
//    func endActivityIndicator() {
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0) {
//            self.activityIndicatorView?.stopAnimating()
//            self.removeAnimate()
//        }
//    }
//
//    
//}
