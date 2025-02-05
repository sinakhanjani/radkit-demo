//
//  PhotoPickupViewController.swift
//  RadKit Module
//
//  Created by Sina khanjani on 10/9/22.
//  Copyright © 2022 Sina Khanjani. All rights reserved.
//

import UIKit
import CropViewController

class PhotoPickupViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let imagePicker = UIImagePickerController()
    var selectedImage: UIImage?
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    var photos: [String] {
        var items = [String]()
        
        for i in 1...32 {
            items.append("d\(i)")
        }
        
        return items
    }
    
    var completion: ((_ data: Data?) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
    }

    @IBAction func cameraButtonTapped() {
        open(type: .camera)
    }
    
    @IBAction func photoGalleryButtonTapped() {
        open(type: .photoLibrary)
    }
    
    static func create(completion: ((_ data: Data?) -> Void)?) -> PhotoPickupViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoPickupViewController") as! PhotoPickupViewController
        vc.completion = completion
        return vc
    }
}

extension PhotoPickupViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RadKitCollectionViewCell
        cell.imageView1.image = UIImage(named: photos[indexPath.item])

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numberOfColumns: CGFloat = 2
        if UIScreen.main.bounds.width > 320 {
            numberOfColumns = 3
        }
        let spaceBetweenCells: CGFloat = 10
        let padding: CGFloat = 40
        let cellDimention = ((collectionView.bounds.width - padding) - (numberOfColumns - 1) * spaceBetweenCells) / numberOfColumns

        return CGSize.init(width: cellDimention, height: cellDimention)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let image = UIImage(named: photos[indexPath.item]), let data = image.pngData() {
            self.dismiss(animated: true) { [weak self] in
                self?.completion?(data)
            }
        }
    }
}

extension PhotoPickupViewController: CropViewControllerDelegate,UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    func open(type: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.delegate = self
            imagePicker.sourceType = type
            imagePicker.allowsEditing = false

            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        let cropController = CropViewController(croppingStyle: croppingStyle, image: image)
        cropController.delegate = self
        // -- Uncomment these if you want to test out restoring to a previous crop setting --
        //cropController.angle = 90 // The initial angle in which the image will be rotated
       cropController.imageCropFrame = CGRect(x: 0, y: 0, width: 1250, height: 1000) //The initial frame that the crop controller will have visible.
        // -- Uncomment the following lines of code to test out the aspect ratio features --
        cropController.aspectRatioPreset = .presetOriginal; //Set the initial aspect ratio as a square
        cropController.aspectRatioLockEnabled = true // The crop box is locked to the aspect ratio and can't be
        cropController.aspectRatioPickerButtonHidden = true
       cropController.rotateButtonsHidden = true
       cropController.rotateClockwiseButtonHidden = true
       cropController.toolbar.resetButtonHidden = true
       cropController.aspectRatioPickerButtonHidden = true
       //        cropController.resetAspectRatioEnabled = false // When tapping 'reset', the aspect ratio will NOT be reset back to default
       cropController.resetAspectRatioEnabled = true // When tapping 'reset', the aspect ratio will NOT be reset back to default
        cropController.doneButtonTitle = "Done"
        cropController.cancelButtonTitle = "Cancel"
       cropController.toolbar.clampButtonHidden = true
        
        picker.dismiss(animated: true, completion: { [weak self] in
            self?.present(cropController, animated: true, completion: nil)
        })
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        self.croppedAngle = angle
        
        if let data = image.jpegData(compressionQuality: 0.04) {
            print("Image Size", data)
            cropViewController.dismiss(animated: false) { [weak self] in
                self?.dismiss(animated: true) { [weak self] in
                    self?.completion?(data)
                }
            }
        }
    }
}
