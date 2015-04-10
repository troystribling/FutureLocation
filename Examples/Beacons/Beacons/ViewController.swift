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
    @IBOutlet var startMonitoringLabel  : UILabel!
    
    var beaconFuture    : FutureStream<[Beacon]>?
    var beaconRegion    : BeaconRegion
    
    let beaconManager   = BeaconManager()
    let estimoteUUID    = "B9407F30-F5F8-466E-AFF9-25556B57FE6D"
    
    required init(coder aDecoder: NSCoder) {
        if let uuid = BeaconStore.getBeacon() {
            self.beaconRegion = BeaconRegion(proximityUUID:uuid, identifier:"Example Beacon")
        } else {
            self.beaconRegion = BeaconRegion(proximityUUID:NSUUID(UUIDString:self.estimoteUUID)!, identifier:"Example Beacon")
            BeaconStore.setBeacons(self.estimoteUUID)
        }
        super.init(coder:aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let uuid = BeaconStore.getBeacon() {
            self.uuidTextField.text = uuid.UUIDString
        }
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        if !BeaconManager.isRangingAvailable() || !BeaconManager.locationServicesEnabled() {
            self.startMonitoringSwitch.enabled = false
            self.uuidTextField.enabled = false
            if BeaconManager.locationServicesEnabled() {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("Beacon ranging not available"), animated:true, completion:nil)
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("Location services not enabled"), animated:true, completion:nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        let beaconsViewController = segue.destinationViewController as! BeaconsViewController
        beaconsViewController.beaconRegion = self.beaconRegion
    }

    @IBAction func toggleMonitoring(sender:AnyObject) {
        if self.beaconManager.isMonitoring {
            self.beaconManager.stopRangingAllBeacons()
            self.beaconManager.stopMonitoringAllRegions()
            self.stateLabel.text = "Not Monitoring"
            self.stateLabel.textColor = UIColor(red:0.6, green:0.0, blue:0.0, alpha:1.0)
            Notify.withMessage("Not Monitoring")
        } else {
            self.startMonitoring()
        }
    }
    
    func startMonitoring() {
        if let beacon = BeaconStore.getBeacon() {
            let regionFuture = self.beaconManager.startMonitoringForRegion(self.beaconRegion, authorization:.AuthorizedAlways)
            self.beaconFuture = regionFuture.flatmap{state -> FutureStream<[Beacon]> in
                switch state {
                case .Start:
                    self.stateLabel.text = "Started Monitoring"
                    self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
                    Notify.withMessage("Started monitoring region '\(self.beaconRegion.identifier)'. Started ranging beacons")
                    return self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
                case .Inside:
                    self.stateLabel.text = "Inside Region"
                    self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
                    if !self.beaconManager.isRangingRegion(self.beaconRegion.identifier) {
                        Notify.withMessage("Entering region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
                        return self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
                    } else {
                        Notify.withMessage("Entered region '\(self.beaconRegion.identifier)'")
                        let errorPromise = StreamPromise<[Beacon]>()
                        errorPromise.failure(AppErrors.rangingBeacons)
                        return errorPromise.future
                    }
                case .Outside:
                    self.stateLabel.text = "Outside Region"
                    self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
                    self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
                    Notify.withMessage("Exited region '\(self.beaconRegion.identifier)'. Stopped ranging beacons")
                    let errorPromise = StreamPromise<[Beacon]>()
                    errorPromise.failure(AppErrors.outOfRegion)
                    return errorPromise.future
                }
            }
            self.beaconFuture?.onSuccess {beacons in
                if UIApplication.sharedApplication().applicationState == .Active && beacons.count > 0 {
                    NSNotificationCenter.defaultCenter().postNotificationName(AppNotification.didUpdateBeacon, object:self.beaconRegion)
                }
                self.beaconsLabel.text = "\(beacons.count)"
            }
            self.beaconFuture?.onFailure {error in
                Notify.withMessage("Error: '\(error.localizedDescription)'")
            }
        } else {
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("No beacon region defined"), animated:true, completion:nil)
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        self.uuidTextField.resignFirstResponder()
        if let newValue = self.uuidTextField.text {
        }
        return true
    }

}

