
//
//  AddEquipmentViewController.swift
//  Master
//
//  Created by Sina khanjani on 10/1/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//

import UIKit

protocol AddEquipmentViewControllerDelegate: AnyObject {
    func addEquipmentButtonTapped(deviceType:DeviceType)
}

class AddEquipmentViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    //(name:"Gas Cooler",image:UIImage(named: DeviceType.ac.imagename())!,type: DeviceType.ac),
    var data: [(name:String,image:UIImage,type:DeviceType)] = [
        (name:"TV",image:UIImage(named: DeviceType.tv.imagename())!,type:DeviceType.tv),(name:"Custom Remote",image:UIImage(named: DeviceType.remotes.imagename())!,type:DeviceType.remotes),(name:"Wireless Switch",image:UIImage(named: DeviceType.wifi.imagename())!,type:DeviceType.wifi),(name:"Switchs",image:UIImage(named: DeviceType.switch6.imagename())!,type:DeviceType.switch6),(name:"Scenario Switchs",image:UIImage(named: DeviceType.switchSenario.imagename())!,type: DeviceType.switchSenario),(name:"Thermostat",image:UIImage(named: DeviceType.thermostat.imagename())!,type:DeviceType.thermostat),(name:"RGB",image:UIImage(named: DeviceType.rgbController.imagename())!,type: DeviceType.rgbController),(name:"Dimmer",image:UIImage(named: DeviceType.dimmer.imagename())!,type: DeviceType.dimmer),
        (name:DeviceType.engine.changed(),image:UIImage(named: DeviceType.engine.imagename())!,type:DeviceType.engine),
        (name:DeviceType.ac.changed(),image:UIImage(named: DeviceType.ac.imagename())!,type:DeviceType.ac),
        (name:DeviceType.humidityControl.changed(),image:UIImage(named: DeviceType.humidityControl.imagename())!,type:DeviceType.humidityControl),
        (name:DeviceType.inputStatus.changed(),image:UIImage(named: DeviceType.inputStatus.imagename())!, type:DeviceType.inputStatus),
        (name:DeviceType.cctv.changed(),image:UIImage(named: DeviceType.cctv.imagename())!, type:DeviceType.cctv)
    ]
    
    weak var delegate:AddEquipmentViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backBarButtonAttribute(color: .black, name: "")
        self.title = "Add Appliance"
    } 
}

extension AddEquipmentViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "centerMainCollectionView", for: indexPath) as! RadKitCollectionViewCell
        let item = self.data[indexPath.item]
        cell.imageView1.image = item.image
        cell.label1.text = item.name
        
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
        
        return CGSize.init(width: cellDimention, height: 140.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.data[indexPath.item]
        self.navigationController?.popViewController(animated: true)
        delegate?.addEquipmentButtonTapped(deviceType: item.type)
    }
}
