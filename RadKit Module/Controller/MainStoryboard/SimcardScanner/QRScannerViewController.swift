//
//  QRScannerViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 6/20/1400 AP.
//  Copyright © 1400 AP Sina Khanjani. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRScannerViewControllerDelegate:AnyObject {
    func qrScannerDidFind(code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var topView: UIView!
    
    let supportedBarCodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean8, AVMetadataObject.ObjectType.aztec]

    // Variable
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    weak var delegate:QRScannerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Implement video capture
        implementVideoCapture()
        
        // 2. Display video capture
        displayVideoCapture()
        
        // 3. start video capture
        captureSession?.startRunning()
        
        // 4. add QRCode frame by defualt zero size so it's mean == hide !
        addQRCodeFrame()
        
        view.bringSubviewToFront(topView)
    }

    
    func implementVideoCapture() {
        captureSession = AVCaptureSession()
        do {
            let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession?.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        } catch {
            print(error)
            return
        }

    }
    
    func displayVideoCapture() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
    }
    
    func addQRCodeFrame() {
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
        }
    }
    
    // MARK: Decoding the QRCode
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
//            let msg = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds // set qrCodeFrameView frame here
            
            if let code = metadataObj.stringValue {
                print("FIND QR CODE: \(code)")
                delegate?.qrScannerDidFind(code: code)
                dismiss(animated: true, completion: nil)
            }
        }
        /*
        if supportedBarCodes.contains(metadataObj.type) {
        let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
        qrCodeFrameView?.frame = barCodeObject!.bounds // set qrCodeFrameView frame here
        if metadataObj.stringValue != nil {
            messageLabel.text = metadataObj.stringValue
           }
        }
        */
    }
    
    @IBAction func dissButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
     
    static func create() -> QRScannerViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QRScannerViewController") as! QRScannerViewController
        
        return vc
    }
}
