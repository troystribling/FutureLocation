//
//  ViewController.swift
//  Beacons
//
//  Created by Troy Stribling on 4/5/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
import FutureLocation

class ViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var beaconsLabel: UILabel!
    @IBOutlet var startMonitoringSwitch: UISwitch!
    @IBOutlet var startMonitoringLabel: UILabel!
    
    var beaconRegion: BeaconRegion
    var beaconFuture: FutureStream<[Beacon]>?

    var progressView = ProgressView()
    var isRanging = false
    
    let beaconManager = BeaconManager()
    let estimoteUUID = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
    
    required init?(coder aDecoder: NSCoder) {
        if let uuid = BeaconStore.getBeacon() {
            beaconRegion = BeaconRegion(proximityUUID: uuid, identifier: "Example Beacon")
        } else {
            beaconRegion = BeaconRegion(proximityUUID: self.estimoteUUID, identifier: "Example Beacon")
            BeaconStore.setBeacon(self.estimoteUUID)
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let uuid = BeaconStore.getBeacon() {
            uuidTextField.text = uuid.uuidString
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !beaconManager.isRangingAvailable() || !self.beaconManager.locationServicesEnabled() {
            startMonitoringSwitch.isEnabled = false
            uuidTextField.isEnabled = false
            startMonitoringLabel.textColor = UIColor.lightGray
            let message = self.beaconManager.locationServicesEnabled() ? "Beacon ranging not available" : "Location services not enabled"
            present(UIAlertController.alertOnErrorWithMessage(message), animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        let beaconsViewController = segue.destination as! BeaconsViewController
        beaconsViewController.beaconRegion = beaconRegion
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return self.beaconRegion.beacons.count > 0
    }

    @IBAction func toggleMonitoring(_ sender: AnyObject) {
        guard !beaconManager.isMonitoring else {
            startMonitoring()
            return
        }
        beaconManager.stopRangingAllBeacons()
        beaconManager.stopMonitoringAllRegions()
        uuidTextField.isEnabled = true
        isRanging = false
        setNotMonitoring()
    }
    
    func startMonitoring() {
        self.progressView.show()
        self.uuidTextField.isEnabled = false
        beaconFuture = self.beaconManager.startMonitoring(for: beaconRegion, authorization: .authorizedAlways).flatMap{ [unowned self] state -> FutureStream<[Beacon]> in
            self.progressView.remove()
            switch state {
            case .start:
                self.setStartedMonitoring()
                self.isRanging = true
                return self.beaconManager.startRangingBeacons(in: self.beaconRegion)
            case .inside:
                self.setInsideRegion()
                guard !self.beaconManager.isRangingRegion(identifier: self.beaconRegion.identifier) else {
                    throw AppError.rangingBeacons
                }
                self.isRanging = true
                return self.beaconManager.startRangingBeacons(in: self.beaconRegion)
            case .outside:
                self.setOutsideRegion()
                self.beaconManager.stopRangingBeacons(in: self.beaconRegion)
                throw AppError.outOfRegion
            }
        }
        beaconFuture!.onSuccess { [unowned self] beacons in
            guard !self.isRanging else {
                return
            }
            if UIApplication.shared.applicationState == .active && beacons.count > 0 {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: AppNotification.didUpdateBeacon), object: self.beaconRegion)
                self.setInsideRegion()
            }
            self.beaconsLabel.text = "\(beacons.count)"
        }
        beaconFuture!.onFailure { [unowned self]  error in
            self.progressView.remove()
            if error is AppError {
                return
            }
            Notify.withMessage("Error: '\(error.localizedDescription)'")
            self.startMonitoringSwitch.isOn = false
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let newValue = self.uuidTextField.text {
            if let uuid = UUID(uuidString: newValue) {
                self.beaconRegion = BeaconRegion(proximityUUID: uuid, identifier: "Example Beacon")
                BeaconStore.setBeacon(uuid)
                self.uuidTextField.resignFirstResponder()
                return true
            } else {
                self.present(UIAlertController.alertOnErrorWithMessage("UUID '\(newValue)' is Invalid"), animated: true, completion: nil)
                return false
            }

        } else {
            return false
        }
    }

    func setNotMonitoring() {
        self.stateLabel.text = "Not Monitoring"
        self.stateLabel.textColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Not Monitoring '\(self.beaconRegion.identifier)'")
        self.beaconsLabel.text = "0"
    }
    
    func setStartedMonitoring() {
        self.stateLabel.text = "Started Monitoring"
        self.stateLabel.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.6, alpha: 1.0)
        Notify.withMessage("Started monitoring region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
    }
    
    func setInsideRegion() {
        self.stateLabel.text = "Inside Region"
        self.stateLabel.textColor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Entered region '\(self.beaconRegion.identifier)'. Started ranging beacons.")
    }
    
    func setOutsideRegion() {
        self.stateLabel.text = "Outside Region"
        self.stateLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Exited region '\(self.beaconRegion.identifier). Stopped ranging beacons.'")
    }

}

