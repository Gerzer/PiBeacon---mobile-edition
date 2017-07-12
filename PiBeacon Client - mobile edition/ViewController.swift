//
//  ViewController.swift
//  PiBeacon Client - mobile edition
//
//  Created by Gabriel Jacoby-Cooper on 6/30/17.
//  Copyright © 2017 Gerzer. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

class ViewController: UIViewController {
	
	@IBOutlet weak var collectionView: UICollectionView!
	var locationManager = CLLocationManager()
	
	@IBAction func refreshBeacons(_ sender: Any) {
		self.collectionView.reloadData()
	}
	
	@IBAction func addBeacon(_ sender: Any) {
		let addBeaconAlert = UIAlertController(title: "Add Beacon", message: "Enter the address (hostname or private IP address) and a custom name for the new beacon:", preferredStyle: UIAlertControllerStyle.alert)
		addBeaconAlert.addTextField { (textField) in
			textField.placeholder = "Address"
			textField.autocapitalizationType = UITextAutocapitalizationType.none
			textField.autocorrectionType = UITextAutocorrectionType.no
			textField.keyboardType = UIKeyboardType.URL
			textField.returnKeyType = UIReturnKeyType.continue
		}
		addBeaconAlert.addTextField { (textField) in
			textField.placeholder = "Name"
			textField.autocapitalizationType = UITextAutocapitalizationType.words
			textField.autocorrectionType = UITextAutocorrectionType.yes
			textField.keyboardType = UIKeyboardType.alphabet
			textField.returnKeyType = UIReturnKeyType.continue
		}
		let addAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default, handler: { (alertAction) in
			let defaults = UserDefaults.standard
			var addressTextField: UITextField? = nil
			var nameTextField: UITextField? = nil
			for textField in addBeaconAlert.textFields! {
				if textField.placeholder == "Address" {
					addressTextField = textField
				} else if textField.placeholder == "Name" {
					nameTextField = textField
				}
			}
			if let beaconAddress = addressTextField!.text {
				if let beaconName = nameTextField!.text {
					if var beaconArray = defaults.array(forKey: "beacons") {
						var doAddBeacon = true
						for beacon in beaconArray {
							if beaconAddress == (beacon as! [String: Any])["address"] as! String {
								doAddBeacon = false
							}
						}
						if doAddBeacon {
							let major = defaults.integer(forKey: "major")
							let minor = defaults.integer(forKey: "minor") + 1
							Alamofire.request("http://" + beaconAddress + "/update", method: HTTPMethod.get, parameters: ["major": String(major, radix: 16, uppercase: true).leftPadding(toLength: 4, withPad: "0"), "minor": String(minor, radix: 16, uppercase: true).leftPadding(toLength: 4, withPad: "0")]).responseString(completionHandler: { (response) in
								if response.result.value == "Success" {
									beaconArray.append(["address": beaconAddress, "name": beaconName, "major": major, "minor": minor])
									defaults.set(beaconArray, forKey: "beacons")
									defaults.set(major, forKey: "major")
									defaults.set(minor, forKey: "minor")
									self.collectionView.reloadData()
								} else {
									let errorAlert = UIAlertController(title: "Beacon Unreachable", message: "The beacon is currently unreachable. Check that it and this device are connected to the same network.", preferredStyle: UIAlertControllerStyle.alert)
									errorAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: nil))
									self.present(errorAlert, animated: true, completion: nil)
								}
							})
						} else {
							let errorAlert = UIAlertController(title: "Beacon Already Added", message: "A beacon with this address has already been added.", preferredStyle: UIAlertControllerStyle.alert)
							errorAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: nil))
							self.present(errorAlert, animated: true, completion: nil)
						}
					} else {
						let major = Int(arc4random_uniform(UInt32(UInt16.max)))
						let minor = 0
						Alamofire.request("http://" + beaconAddress + "/update", method: HTTPMethod.get, parameters: ["major": String(major, radix: 16, uppercase: true).leftPadding(toLength: 4, withPad: "0"), "minor": String(minor, radix: 16, uppercase: true).leftPadding(toLength: 4, withPad: "0")]).responseString(completionHandler: { (response) in
							if response.result.value == "Success" {
								defaults.set([["address": beaconAddress, "name": beaconName, "major": major, "minor": minor]], forKey: "beacons")
								defaults.set(major, forKey: "major")
								defaults.set(minor, forKey: "minor")
								self.collectionView.reloadData()
							} else {
								let errorAlert = UIAlertController(title: "Beacon Unreachable", message: "The beacon is currently unreachable. Check that it and this device are connected to the same network.", preferredStyle: UIAlertControllerStyle.alert)
								errorAlert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.default, handler: nil))
								self.present(errorAlert, animated: true, completion: nil)
							}
						})
					}
				}
			}
			self.collectionView.reloadData()
		})
		addBeaconAlert.addAction(addAction)
		addBeaconAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		addBeaconAlert.preferredAction = addAction
		self.present(addBeaconAlert, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		collectionView.dataSource = self
//		if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
//			let proximityUUID = UUID(uuidString: "618496F1-C20A-4E8F-BA2A-A00CCEE44565")
//			self.locationManager.startRangingBeacons(in: CLBeaconRegion(proximityUUID: proximityUUID!, identifier: "com.gerzer.PiBeaconRegion"))
//		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
}

extension ViewController: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let defaults = UserDefaults.standard
		if let beaconArray = defaults.array(forKey: "beacons") {
			return beaconArray.count
		} else {
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BeaconCell", for: indexPath) as! BeaconCell
		let defaults = UserDefaults.standard
		if let beaconArray = defaults.array(forKey: "beacons") as? [[String: Any]] {
			cell.beaconNameLabel.text = beaconArray[indexPath.row]["name"] as? String
			cell.setAddress(address: beaconArray[indexPath.row]["address"]! as! String)
			cell.setMajorAndMinor(major: beaconArray[indexPath.row]["major"] as! Int, minor: beaconArray[indexPath.row]["minor"] as! Int)
			Alamofire.request("http://" + (beaconArray[indexPath.row]["address"]! as! String) + "/status", method: HTTPMethod.get).responseString(completionHandler: { (response) in
				if response.error == nil {
					cell.beaconSwitch.isEnabled = true
					switch response.result.value {
					case ("Enabled")?:
						cell.beaconSwitch.setOn(true, animated: true)
						break
					case ("Disabled")?:
						cell.beaconSwitch.setOn(false, animated: true)
						break
					default:
						cell.beaconSwitch.isEnabled = false
						break
					}
				} else {
					cell.beaconSwitch.isEnabled = false
				}
			})
		}
		return cell
	}
	
}

extension ViewController: CLLocationManagerDelegate {
	
	func configureLocationServices() {
		self.locationManager.delegate = self
		let authorizationStatus = CLLocationManager.authorizationStatus()
		switch authorizationStatus {
		case .notDetermined:
			self.locationManager.requestWhenInUseAuthorization()
			break
		default:
			break
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
		
	}
	
}

extension String {
	
	func leftPadding(toLength: Int, withPad character: Character) -> String {
		let newLength = self.characters.count
		if newLength < toLength {
			return String(repeatElement(character, count: toLength - newLength)) + self
		} else {
			return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
		}
	}
	
}
