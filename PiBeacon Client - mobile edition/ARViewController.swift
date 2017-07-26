//
//  ARViewController.swift
//  PiBeacon Client - mobile edition
//
//  Created by Gerzer on 7/21/17.
//  Copyright © 2017 Gerzer. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class ARViewController: UIViewController {
	
	@IBOutlet weak var sceneView: ARSCNView!
	@IBOutlet weak var debugLabel: UILabel!
	var beaconRootNode: SCNNode!
	var didRangeImmediate = false
	var didRangeNear = false
	var didRangeFar = false
	var currentAnchor: ARAnchor?
	
	@IBAction func doneButtonTapped(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	func loadBeaconScene() {
		let beaconScene = SCNScene(named: "Beacon.scn")
		beaconRootNode = beaconScene?.rootNode
		(beaconRootNode.childNode(withName: "immediate", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0
		(beaconRootNode.childNode(withName: "immediate", recursively: true)?.geometry as? SCNTube)?.outerRadius = 0
		(beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0
		(beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.outerRadius = 0
		(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0
		(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.outerRadius = 0
	}
	
	func setBeaconRangingStatus(proximity: CLProximity) {
		switch proximity {
		case CLProximity.immediate:
			debugLabel.text = "Immediate"
			didRangeImmediate = true
		case CLProximity.near:
			debugLabel.text = "Near"
			if didRangeImmediate {
				if let camera = sceneView.pointOfView {
					if let newDistance = beaconRootNode.childNode(withName: "sphere", recursively: true)?.worldPosition.distance(from: camera.worldPosition) {
						(beaconRootNode.childNode(withName: "immediate", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0.5
						(beaconRootNode.childNode(withName: "immediate", recursively: true)?.geometry as? SCNTube)?.outerRadius = CGFloat(newDistance) * 8
						(beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0
						(beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.outerRadius = 0
						(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0
						(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.outerRadius = 0
						didRangeNear = true
					}
				}
			}
		case CLProximity.far:
			debugLabel.text = "Far"
			if didRangeImmediate && didRangeNear {
				if let camera = sceneView.pointOfView {
					if let newDistance = beaconRootNode.childNode(withName: "sphere", recursively: true)?.worldPosition.distance(from: camera.worldPosition) {
						if let oldRadius = (beaconRootNode.childNode(withName: "immediate", recursively: true)?.geometry as? SCNTube)?.outerRadius {
							(beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.innerRadius = oldRadius
							(beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.outerRadius = CGFloat(newDistance) * 8
							(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.innerRadius = 0
							(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.outerRadius = 0
							didRangeFar = true
						}
					}
				}
			}
		case CLProximity.unknown:
			debugLabel.text = "Unknown"
			if didRangeImmediate && didRangeNear && didRangeFar {
				if let camera = sceneView.pointOfView {
					if let newDistance = beaconRootNode.childNode(withName: "sphere", recursively: true)?.worldPosition.distance(from: camera.worldPosition) {
						if let oldRadius = (beaconRootNode.childNode(withName: "near", recursively: true)?.geometry as? SCNTube)?.outerRadius {
							if oldRadius > 0 {
								(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.innerRadius = oldRadius
								(beaconRootNode.childNode(withName: "far", recursively: true)?.geometry as? SCNTube)?.outerRadius = CGFloat(newDistance) * 8
							}
						}
					}
				}
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		sceneView.delegate = self
		sceneView.scene = SCNScene(named: "Main.scn")!
		loadBeaconScene()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		let configuration = ARWorldTrackingSessionConfiguration()
		sceneView.session.run(configuration)
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let touchLocation = touches.first?.location(in: sceneView) {
			if let hitTestResult = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.featurePoint).first {
				if currentAnchor != nil {
					sceneView.session.remove(anchor: currentAnchor!)
				} else {
					debugLabel.text = "Stand by beacon, then walk away slowly"
				}
				currentAnchor = ARAnchor(transform: hitTestResult.worldTransform)
				sceneView.session.add(anchor: currentAnchor!)
				return
			}
		}
	}
	
}

extension ARViewController: ARSCNViewDelegate {
	
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		let beaconNode = beaconRootNode.clone()
		beaconNode.position = SCNVector3Zero
		beaconNode.scale = SCNVector3Make(0.0625, 0.0625, 0.0625)
		node.addChildNode(beaconNode)
	}
	
}

extension SCNVector3 {
	
	func distance(from: SCNVector3) -> Float {
		let xd = from.x - x
		let yd = from.y - y
		let zd = from.z - z
		let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))
		if distance < 0 {
			return distance * -1
		} else {
			return distance
		}
	}
	
}
