//
//  UIViewControllerExtension.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import UIKit
import AVFoundation
import CDAlertView
//import MaterialShowcase
//import SideMenu
import Lottie
import AVKit
import AVFoundation
import LocalAuthentication


extension UIViewController {
    
    func backBarButtonAttribute(color: UIColor, name: String) {
        //
    }
    
}

// MENU ANIMATION
extension UIViewController {
    
    func showAnimate() {
        self.view.transform = CGAffineTransform.init(scaleX: 1.0, y: 1.0)
        self.view.alpha = 0.0
        UIView.animate(withDuration: 0.4) {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform.identity
        }
    }
    
    func removeAnimate(boxView: UIView? = nil) {
        if let boxView = boxView {
            self.sideHideAnimate(view: boxView)
        }
        UIView.animate(withDuration: 0.4, animations: {
            self.view.transform = CGAffineTransform.init(scaleX: 1.0, y: 1.0)
            self.view.alpha = 0.0
        }) { (finished) in
            if finished {
                self.view.removeFromSuperview()
            }
        }
    }
    
    func sideShowAnimate(view: UIView) {
        view.transform = CGAffineTransform.init(translationX: UIScreen.main.bounds.width, y: 0)
        UIView.animate(withDuration: 1.4) {
            view.transform = CGAffineTransform.identity
        }
    }
    
    func sideHideAnimate(view: UIView) {
        UIView.animate(withDuration: 1.4, animations: {
            view.transform = CGAffineTransform.init(translationX: UIScreen.main.bounds.width, y: 0)
        }) { (finished) in
            if finished {
                //
            }
        }
    }
    
}

extension UIViewController {
    
    func presentAlertActionWithTextField(message: String,title:String,textFieldPlaceHolder:String, completion: @escaping (_ name: String) -> Void) {
//        let titleAttribute = NSAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 15.0)!, NSAttributedString.Key.foregroundColor : UIColor.label])
//        let attributeMsg = NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.init(name: Constant.Fonts.fontOne, size: 13.0)!, NSAttributedString.Key.foregroundColor : UIColor.label])
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
//        alertController.setValue(attributeMsg, forKey: "attributedMessage")
//        alertController.setValue(titleAttribute, forKey: "attributedTitle")
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = textFieldPlaceHolder
//            textField.font = UIFont.persianFont(size: 14)
//            textField.textColor = .black
            textField.textAlignment = .center
        }
        let saveAction = UIAlertAction(title: "Done", style: UIAlertAction.Style.default, handler: { [weak self] alert -> Void in
            guard let self = self else { return }
            let firstTextField = alertController.textFields![0] as UITextField
            if firstTextField.text! != "" {
                completion(firstTextField.text!)
            } else {
                self.presentIOSAlertWarning(message: "Please specify a name!") {
                    //
                }
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })
        cancelAction.setValue(UIColor.RADGreen, forKey: "titleTextColor")
        saveAction.setValue(UIColor.RADGreen, forKey: "titleTextColor")

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentIOSAlertWarning(message: String, completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)

        let doneAction = UIAlertAction.init(title: "Done", style: .cancel) { [weak self] (action) in
            guard let _ = self else { return }
            completion()
        }
        alertController.addAction(doneAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentIOSAlertWarningWithTwoButton(message: String, buttonOneTitle: String, buttonTwoTitle: String, handlerButtonOne: @escaping () -> Void, handlerButtonTwo: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)
        let doneAction1 = UIAlertAction.init(title: buttonOneTitle, style: .default) { (action) in
            handlerButtonOne()
        }
        let doneAction2 = UIAlertAction.init(title: buttonTwoTitle, style: .default) { (action) in
            handlerButtonTwo()
        }
        alertController.addAction(doneAction1)
        alertController.addAction(doneAction2)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func phoneNumberCondition(phoneNumber number: String) -> Bool {
        guard !number.isEmpty else {
            let message = "The mobile number is empty!"
            presentIOSAlertWarning(message: message, completion: {})
            return false
        }
        let startIndex = number.startIndex
        let zero = number[startIndex]
        guard zero == "0" else {
            let message = "Enter your mobile number with zero!"
            presentIOSAlertWarning(message: message, completion: {})
            return false
        }
        guard number.count == 11 else {
            let message = "The mobile number must be eleven digits!"
            presentIOSAlertWarning(message: message, completion: {})
            return false
        }
        
        return true
    }
}


extension UIViewController {
    func configureTouchXibViewController(bgView: UIView) {
        self.view.endEditing(true)
        let touch = UITapGestureRecognizer(target: self, action: #selector(dismissTouchPressed))
        bgView.addGestureRecognizer(touch)
    }
    
    @objc func dismissTouchPressed() {
        removeAnimate()
    }
}

extension UIViewController {
    
    func loadLottieJson(bundleName name: String, lottieView: UIView) {
        // Create Boat Animation
        let boatAnimation = AnimationView(name: name)
        // Set view to full screen, aspectFill
        boatAnimation.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        boatAnimation.contentMode = .scaleAspectFill
        boatAnimation.frame = lottieView.bounds
        // Add the Animation
        lottieView.addSubview(boatAnimation)
        boatAnimation.loopMode = .loop
        boatAnimation.play()
    }
}


extension UIViewController: AVPlayerViewControllerDelegate {
    
    func playVideo(url: URL) {
        let player = AVPlayer.init(url: url)
        let playerController = AVPlayerViewController()
        playerController.delegate = self
        playerController.player = player
        //self.addChildViewController(playerController)
        //self.view.addSubview(playerController.view)
        //playerController.view.frame = self.view.frame
        present(playerController, animated: true, completion: nil)
        player.play()
    }
    
    
}
extension UIViewController {
    
    func addChangedLanguagedToViewController() {
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: Constant.Notify.LanguageChangedNotify, object: nil)
        
    }
    
    @objc private func languageChanged() {
        for view in view.subviews {
            view.setNeedsDisplay()
            view.setNeedsLayout()
            view.layoutIfNeeded()
            view.updateFocusIfNeeded()
            view.updateConstraintsIfNeeded()
            view.reloadInputViews()
        }
        loadViewIfNeeded()
    }
}

extension UIViewController {
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }

}

extension UIViewController {
    
    @objc func backSenarioButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
}


extension UIViewController {
    func authenticateWithTouchID(_ escape: @escaping (_ ok: Bool) -> Void) {
        let localAuthContext = LAContext()
        let faText = "Please enter a password to enter"
        var authError: NSError?
        if !localAuthContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            if let error = authError {
                print(error.localizedDescription)
            }
            self.present(AuthenticationViewController.create(completion: { isOk in
                escape(isOk)
            }), animated: true, completion: nil)
            
            return
        }
        localAuthContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: faText, reply: { (success: Bool, error: Error?) -> Void in
            if !success {
                if let error = error {
                    switch error {
                    case LAError.authenticationFailed:
                        print("Authentication failed")
                    case LAError.passcodeNotSet:
                        print("Passcode not set")
                    case LAError.systemCancel:
                        print("Authentication was canceled by system")
                    case LAError.userCancel:
                        print("Authentication was canceled by the user")
                    case LAError.touchIDNotEnrolled:
                        print("Authentication could not start because Touch ID has no enrolled fingers.")
                    case LAError.touchIDNotAvailable:
                        print("Authentication could not start because Touch ID is not available.")
                    case LAError.userFallback:
                        print("User tapped the fallback button (Enter Password).")
                    default:
                        print(error.localizedDescription)
                    }
                }
                OperationQueue.main.addOperation({
                    self.present(AuthenticationViewController.create(completion: { isOk in
                        escape(isOk)
                    }), animated: true, completion: nil)
                })
            } else {
                escape(true)
            }
        })
    }
}
