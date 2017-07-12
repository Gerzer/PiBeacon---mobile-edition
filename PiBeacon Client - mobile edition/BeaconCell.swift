//
//  BeaconCell.swift
//  PiBeacon Client - mobile edition
//
//  Created by Gabriel Jacoby-Cooper on 7/6/17.
//  Copyright © 2017 Gerzer. All rights reserved.
//

import UIKit
import Alamofire

class BeaconCell: UICollectionViewCell {
	
	@IBOutlet weak var beaconNameLabel: UILabel!
	@IBOutlet weak var beaconSwitch: UISwitch!
	var address = ""
	var major = 0
	var minor = 0
	
	@IBAction func beaconSwitchStateChanged(_ sender: Any) {
		if self.beaconSwitch.isOn {
			Alamofire.request("http://" + self.address + "/enable", method: HTTPMethod.post).responseString(completionHandler: { (response) in
				if response.result.value != "Success" {
					self.beaconSwitch.setOn(false, animated: true)
					let errorAlert = UIAlertController(title: "Beacon Unreachable", message: "The beacon is currently unreachable. Check that it and this device are connected to the same network.", preferredStyle: UIAlertControllerStyle.alert)
					errorAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: nil))
					self.window?.rootViewController?.present(errorAlert, animated: true, completion: nil)
				}
			})
		} else {
			Alamofire.request("http://" + self.address + "/disable", method: HTTPMethod.post).responseString(completionHandler: { (response) in
				if response.result.value != "Success" {
					self.beaconSwitch.setOn(true, animated: true)
					let errorAlert = UIAlertController(title: "Beacon Unreachable", message: "The beacon is currently unreachable. Check that it and this device are connected to the same network.", preferredStyle: UIAlertControllerStyle.alert)
					errorAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: nil))
					self.window?.rootViewController?.present(errorAlert, animated: true, completion: nil)
				}
			})
		}
	}
	
	@IBAction func beaconInfoButtonTapped(_ sender: Any) {
		let beaconInfoAlert = UIAlertController(title: "Beacon Info", message: "This beacon has a Major value of " + String(self.major) + " and a Minor value of " + String(self.minor) + ".", preferredStyle: UIAlertControllerStyle.actionSheet)
		beaconInfoAlert.addAction(UIAlertAction(title: "Rename", style: UIAlertActionStyle.default, handler: { (alertAction) in
			let beaconRenameAlert = UIAlertController(title: "Rename Beacon", message: "Enter a new name for the beacon:", preferredStyle: UIAlertControllerStyle.alert)
			beaconRenameAlert.addTextField(configurationHandler: { (textField) in
				textField.placeholder = "Name"
				textField.autocapitalizationType = UITextAutocapitalizationType.words
				textField.autocorrectionType = UITextAutocorrectionType.yes
				textField.keyboardType = UIKeyboardType.alphabet
				textField.returnKeyType = UIReturnKeyType.continue
			})
			let renameAction = UIAlertAction(title: "Rename", style: UIAlertActionStyle.default, handler: { (alertAction) in
				let defaults = UserDefaults.standard
				var beaconArray = defaults.array(forKey: "beacons")!
				for index in (0..<beaconArray.count) {
					if self.address == (beaconArray[index] as! [String: Any])["address"] as! String {
						if let beaconName = beaconRenameAlert.textFields![0].text {
							var beaconDictionary = beaconArray.remove(at: index) as! [String: Any]
							beaconDictionary.updateValue(beaconName, forKey: "name")
							beaconArray.insert(beaconDictionary, at: index)
							defaults.set(beaconArray, forKey: "beacons")
							(self.window?.rootViewController as? ViewController)?.collectionView.reloadData()
							break
						}
					}
				}
			})
			beaconRenameAlert.addAction(renameAction)
			beaconRenameAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
			beaconRenameAlert.preferredAction = renameAction
			self.window?.rootViewController?.present(beaconRenameAlert, animated: true, completion: nil)
		}))
		beaconInfoAlert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive, handler: { (alertAction) in
			let defaults = UserDefaults.standard
			var beaconArray = defaults.array(forKey: "beacons")!
			for index in (0..<beaconArray.count) {
				if self.address == (beaconArray[index] as! [String: Any])["address"] as! String {
					beaconArray.remove(at: index)
					defaults.set(beaconArray, forKey: "beacons")
					(self.window?.rootViewController as? ViewController)?.collectionView.reloadData()
					break
				}
			}
		}))
		beaconInfoAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		self.window?.rootViewController?.present(beaconInfoAlert, animated: true, completion: nil)
	}
	
	func setAddress(address: String) {
		self.address = address
	}
	
	func setMajorAndMinor(major: Int, minor: Int) {
		self.major = major
		self.minor = minor
	}
	
}
