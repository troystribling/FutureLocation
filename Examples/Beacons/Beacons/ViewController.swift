//
//  ViewController.swift
//  Beacons
//
//  Created by Troy Stribling on 4/5/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreLocation
import FutureLocation

class ViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var stateLabel            : UILabel!
    @IBOutlet var uuidTextField         : UITextField!
    @IBOutlet var beaconsLabel          : UILabel!
    @IBOutlet var startMonitoringSwitch : UISwitch!
    
    var region          : CircularRegion?
    var regionFuture    : FutureStream<RegionState>?
    var beaconFuture    : FutureStream<[CLPlacemark]>?
    
    let addressManager  = LocationManager()
    let beaconManager   = BeaconManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createRegion(sender:AnyObject) {
        if LocationManager.locationServicesEnabled() {
        } else {
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("Location services disabled"), animated:true, completion:nil)
        }
    }
    
    @IBAction func toggleMonitoring(sender:AnyObject) {
        if let region = self.region {
            if self.beaconManager.isMonitoring {
                self.beaconManager.stopRangingAllBeacons()
                self.beaconManager.stopMonitoringAllRegions()
                self.stateLabel.text = "Not Monitoring"
                self.stateLabel.textColor = UIColor(red:0.6, green:0.0, blue:0.0, alpha:1.0)
                Notify.withMessage("Not Monitoring '\(region.identifier)'")
            } else {
                self.startMonitoring(region)
            }
        }
    }
    
    func startMonitoring(region:CircularRegion) {
//        self.regionFuture = self.regionManager.startMonitoringForRegion(region, authorization:.AuthorizedAlways)
//        self.regionFuture?.onSuccess {state in
//            switch state {
//            case .Start:
//                self.stateLabel.text = "Started Monitoring"
//                self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
//                Notify.withMessage("Started monitoring region '\(region.identifier)'")
//            case .Inside:
//                self.stateLabel.text = "Inside Region"
//                self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
//                Notify.withMessage("Entered region '\(region.identifier)'")
//            case .Outside:
//                self.stateLabel.text = "Outside Region"
//                self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
//                Notify.withMessage("Exited region '\(region.identifier)'")
//            }
//        }
//        self.regionFuture?.onFailure {error in
//            Notify.withMessage("Error: '\(error.localizedDescription)'")
//        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        self.uuidTextField.resignFirstResponder()
        if let newValue = self.uuidTextField.text {
        }
        return true
    }

}

