//
//  ManualViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 9/17/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import UIKit
import WebKit

class ManualViewController: UIViewController {

    let webView: WKWebView = {
        let wb = WKWebView()
        return wb
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Help"
        view.addSubview(webView)
        webView.frame = view.frame
        if let url = URL(string: "http://imaxbms.com/help") {
            let req = URLRequest(url: url)
            webView.load(req)
        }
    }
}
