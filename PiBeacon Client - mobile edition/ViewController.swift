//
//  ViewController.swift
//  PiBeacon Client - mobile edition
//
//  Created by Gabriel Jacoby-Cooper on 6/30/17.
//  Copyright © 2017 Gerzer. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
	
	@IBOutlet weak var collectionView: UICollectionView!
	var locationManager = CLLocationManager()
	var beaconRegion: CLBeaconRegion? = nil
	
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
		addBeaconAlert.addAction(UIAlertAction(title: "Add Beacon", style: UIAlertActionStyle.default, handler: { (alertAction) in
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
						beaconArray.append(["address": beaconAddress, "name": beaconName])
						defaults.set(beaconArray, forKey: "beacons")
					} else {
						defaults.set([["address": beaconAddress, "name": beaconName]], forKey: "beacons")
					}
				}
			}
			self.collectionView.reloadData()
		}))
		addBeaconAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
		self.present(addBeaconAlert, animated: true, completion: nil)
	}
	
	func monitorBeacons() {
		if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
			let proximityUUID = UUID(uuidString: "618496F1-C20A-4E8F-BA2A-A00CCEE44565")
			self.locationManager.startRangingBeacons(in: CLBeaconRegion(proximityUUID: proximityUUID!, identifier: "com.gerzer.PiBeaconRegion"))
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		collectionView.dataSource = self
		if let guardedBeaconRegion = self.beaconRegion {
			locationManager.startRangingBeacons(in: guardedBeaconRegion)
		}
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
		if let beaconArray = defaults.array(forKey: "beacons") as? [[String: String]] {
			cell.beaconNameLabel.text = beaconArray[indexPath.row]["name"]
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
				self.locationManager.requestAlwaysAuthorization()
				break
			default:
				break
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
		
	}
	
}
