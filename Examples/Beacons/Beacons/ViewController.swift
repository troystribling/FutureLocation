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

    var progressView    = ProgressView()
    var isRanging       = false
    
    let beaconManager   = BeaconManager()
    let estimoteUUID    = NSUUID(UUIDString:"B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
    
    required init(coder aDecoder: NSCoder) {
        if let uuid = BeaconStore.getBeacon() {
            self.beaconRegion = BeaconRegion(proximityUUID:uuid, identifier:"Example Beacon")
        } else {
            self.beaconRegion = BeaconRegion(proximityUUID:self.estimoteUUID, identifier:"Example Beacon")
            BeaconStore.setBeacon(self.estimoteUUID)
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
            self.startMonitoringLabel.textColor = UIColor.lightGrayColor()
            let message = BeaconManager.locationServicesEnabled() ? "Beacon ranging not available" : "Location services not enabled"
            self.presentViewController(UIAlertController.alertOnErrorWithMessage(message), animated:true, completion:nil)
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
            self.uuidTextField.enabled = true
            self.isRanging = false
            self.setNotMonitoring()
        } else {
            self.startMonitoring()
        }
    }
    
    func startMonitoring() {
        self.progressView.show()
        if let beacon = BeaconStore.getBeacon() {
            self.uuidTextField.enabled = false
            self.beaconFuture = self.beaconManager.startMonitoringForRegion(self.beaconRegion, authorization:.AuthorizedAlways).flatmap{state -> FutureStream<[Beacon]> in
                self.progressView.remove()
                switch state {
                case .Start:
                    self.setStartedMonitoring()
                    self.isRanging = true
                    return self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
                case .Inside:
                    self.setInsideRegion()
                    if !self.beaconManager.isRangingRegion(self.beaconRegion.identifier) {
                        self.isRanging = true
                        return self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
                    } else {
                        let errorPromise = StreamPromise<[Beacon]>()
                        errorPromise.failure(AppErrors.rangingBeacons)
                        return errorPromise.future
                    }
                case .Outside:
                    self.setOutsideRegion()
                    self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
                    let errorPromise = StreamPromise<[Beacon]>()
                    errorPromise.failure(AppErrors.outOfRegion)
                    return errorPromise.future
                }
            }
            self.beaconFuture?.onSuccess {beacons in
                if self.isRanging {
                    if UIApplication.sharedApplication().applicationState == .Active && beacons.count > 0 {
                        NSNotificationCenter.defaultCenter().postNotificationName(AppNotification.didUpdateBeacon, object:self.beaconRegion)
                        self.setInsideRegion()
                    }
                    self.beaconsLabel.text = "\(beacons.count)"
                }
            }
            self.beaconFuture?.onFailure {error in
                self.progressView.remove()
                if error.domain != AppErrors.domain {
                    Notify.withMessage("Error: '\(error.localizedDescription)'")
                    self.startMonitoringSwitch.on = false
                }
            }
        } else {
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("No beacon region defined"), animated:true, completion:nil)
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        if let newValue = self.uuidTextField.text {
            if let uuid = NSUUID(UUIDString:newValue) {
                self.beaconRegion = BeaconRegion(proximityUUID:uuid, identifier:"Example Beacon")
                BeaconStore.setBeacon(uuid)
                self.uuidTextField.resignFirstResponder()
                return true
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(newValue)' is Invalid"), animated:true, completion:nil)
                return false
            }

        } else {
            return false
        }
    }

    func setNotMonitoring() {
        self.stateLabel.text = "Not Monitoring"
        self.stateLabel.textColor = UIColor(red:0.6, green:0.0, blue:0.0, alpha:1.0)
        Notify.withMessage("Not Monitoring '\(self.beaconRegion.identifier)'")
        self.beaconsLabel.text = "0"
    }
    
    func setStartedMonitoring() {
        self.stateLabel.text = "Started Monitoring"
        self.stateLabel.textColor = UIColor(red:0.6, green:0.4, blue:0.6, alpha:1.0)
        Notify.withMessage("Started monitoring region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
    }
    
    func setInsideRegion() {
        self.stateLabel.text = "Inside Region"
        self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
        Notify.withMessage("Entered region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
    }
    
    func setOutsideRegion() {
        self.stateLabel.text = "Outside Region"
        self.stateLabel.textColor = UIColor(red:0.6, green:0.6, blue:0.0, alpha:1.0)
        Notify.withMessage("Exited region '\(self.beaconRegion.identifier). Stopped ranging beacons.'")
    }

}

