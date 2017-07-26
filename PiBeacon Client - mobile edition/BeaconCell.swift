//
//  BeaconCell.swift
//  PiBeacon Client - mobile edition
//
//  Created by Gerzer on 7/6/17.
//  Copyright © 2017 Gerzer. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

class BeaconCell: UICollectionViewCell {
	
	@IBOutlet weak var beaconNameLabel: UILabel!
	@IBOutlet weak var beaconSwitch: UISwitch!
	var address = ""
	var major = 0
	var minor = 0
	var arController: ARViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ARController") as! ARViewController
	
	@IBAction func beaconSwitchStateChanged(_ sender: Any) {
		if beaconSwitch.isOn {
			(window?.rootViewController as? ViewController)?.activityIndicatorLabel.text = "Enabling Beacon..."
			(window?.rootViewController as? ViewController)?.activityIndicatorContainerView.isHidden = false
			Alamofire.request("http://" + address + "/enable", method: HTTPMethod.post).responseString(completionHandler: { (response) in
				(self.window?.rootViewController as? ViewController)?.activityIndicatorContainerView.isHidden = true
				if response.result.value != "Success" {
					self.beaconSwitch.setOn(false, animated: true)
					let errorAlert = UIAlertController(title: "Beacon Unreachable", message: "The beacon is currently unreachable. Check that it and this device are connected to the same network.", preferredStyle: UIAlertControllerStyle.alert)
					errorAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: nil))
					self.window?.rootViewController?.present(errorAlert, animated: true, completion: nil)
				}
			})
		} else {
			(window?.rootViewController as? ViewController)?.activityIndicatorLabel.text = "Disabling Beacon..."
			(window?.rootViewController as? ViewController)?.activityIndicatorContainerView.isHidden = false
			Alamofire.request("http://" + address + "/disable", method: HTTPMethod.post).responseString(completionHandler: { (response) in
				(self.window?.rootViewController as? ViewController)?.activityIndicatorContainerView.isHidden = true
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
		let beaconInfoAlert = UIAlertController(title: "Beacon Info", message: "This beacon has a Major value of " + String(major) + " and a Minor value of " + String(minor) + ". Its UUID is 618496F1-C20A-4E8F-BA2A-A00CCEE44565.", preferredStyle: UIAlertControllerStyle.actionSheet)
		beaconInfoAlert.addAction(UIAlertAction(title: "Configure HTTP Requests", style: UIAlertActionStyle.default, handler: { (alertAction) in
			let beaconConfigureHTTPRequestsAlert = UIAlertController(title: "Configure Beacon's HTTP Requests", message: "Enter URLs to which to send HTTP GET requests upon entering or exiting the beacon's range (leave one or both text field blank to not send requests):", preferredStyle: UIAlertControllerStyle.alert)
			beaconConfigureHTTPRequestsAlert.addTextField(configurationHandler: { (textField) in
				textField.placeholder = "Enter"
				textField.autocapitalizationType = UITextAutocapitalizationType.none
				textField.autocorrectionType = UITextAutocorrectionType.no
				textField.keyboardType = UIKeyboardType.URL
				textField.returnKeyType = UIReturnKeyType.continue
			})
			beaconConfigureHTTPRequestsAlert.addTextField(configurationHandler: { (textField) in
				textField.placeholder = "Exit"
				textField.autocapitalizationType = UITextAutocapitalizationType.none
				textField.autocorrectionType = UITextAutocorrectionType.no
				textField.keyboardType = UIKeyboardType.URL
				textField.returnKeyType = UIReturnKeyType.continue
			})
			let configureAction = UIAlertAction(title: "Configure", style: UIAlertActionStyle.default, handler: { (alertAction) in
				let defaults = UserDefaults.standard
				var enterTextField: UITextField? = nil
				var exitTextField: UITextField? = nil
				for textField in beaconConfigureHTTPRequestsAlert.textFields! {
					if textField.placeholder == "Enter" {
						enterTextField = textField
					} else if textField.placeholder == "Exit" {
						exitTextField = textField
					}
				}
				var beaconArray = defaults.array(forKey: "beacons")!
				for index in (0..<beaconArray.count) {
					if self.address == (beaconArray[index] as! [String: Any])["address"] as! String {
						if let enterURL = enterTextField!.text {
							if let exitURL = exitTextField!.text {
								var beaconDictionary = beaconArray.remove(at: index) as! [String: Any]
								beaconDictionary.updateValue(enterURL, forKey: "enter")
								beaconDictionary.updateValue(exitURL, forKey: "exit")
								beaconArray.insert(beaconDictionary, at: index)
								defaults.set(beaconArray, forKey: "beacons")
								(self.window?.rootViewController as? ViewController)?.collectionView.reloadData()
								break
							}
						}
					}
				}
			})
			beaconConfigureHTTPRequestsAlert.addAction(configureAction)
			beaconConfigureHTTPRequestsAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
			beaconConfigureHTTPRequestsAlert.preferredAction = configureAction
			self.window?.rootViewController?.present(beaconConfigureHTTPRequestsAlert, animated: true, completion: nil)
		}))
		beaconInfoAlert.addAction(UIAlertAction(title: "Measure Signal", style: UIAlertActionStyle.default, handler: { (alertAction) in
			let proximityUUID = UUID(uuidString: "618496F1-C20A-4E8F-BA2A-A00CCEE44565")
			let defaults = UserDefaults.standard
			let beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID!, major: UInt16(defaults.integer(forKey: "major")), minor: UInt16(self.minor), identifier: "com.gerzer.PiBeacon-Region")
			(self.window?.rootViewController as? ViewController)?.locationManager.startRangingBeacons(in: beaconRegion)
//			(self.window?.rootViewController as? ViewController)?.performSegue(withIdentifier: "ARSegue", sender: self)
			self.arController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ARController") as! ARViewController
			(self.window?.rootViewController as? ViewController)?.present(self.arController, animated: true, completion: nil)
		}))
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
					if let monitoredRegions = (self.window?.rootViewController as? ViewController)?.locationManager.monitoredRegions {
						for region in monitoredRegions {
							if let beaconRegion = region as? CLBeaconRegion {
								if let minor = beaconRegion.minor as? Int {
									if minor == (beaconArray[index] as! [String: Any])["minor"] as! Int {
										(self.window?.rootViewController as? ViewController)?.locationManager.stopMonitoring(for: beaconRegion)
										break
									}
								}
							}
						}
					}
					beaconArray.remove(at: index)
					defaults.set(beaconArray, forKey: "beacons")
					(self.window?.rootViewController as? ViewController)?.collectionView.reloadData()
					break
				}
			}
		}))
		beaconInfoAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		window?.rootViewController?.present(beaconInfoAlert, animated: true, completion: nil)
	}
	
	func setAddress(address: String) {
		self.address = address
	}
	
	func setMajorAndMinor(major: Int, minor: Int) {
		self.major = major
		self.minor = minor
	}
	
}
