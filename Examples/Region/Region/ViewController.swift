//
//  ViewController.swift
//  Region
//
//  Created by Troy Stribling on 4/3/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
import FutureLocation

class ViewController: UITableViewController {

    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var latituteLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var address1Label: UILabel!
    @IBOutlet var address2Label: UILabel!
    @IBOutlet var address3Label: UILabel!
    @IBOutlet var startMonitoringSwitch: UISwitch!
    @IBOutlet var startMonitoringLabel: UILabel!
    @IBOutlet var createRegionButton: UIButton!
    
    var region: CircularRegion?

    let locationManager = LocationManager()
    let regionManager   = RegionManager()
    
    let progressView    = ProgressView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startMonitoringLabel.textColor = UIColor.lightGray
        startMonitoringSwitch.isOn = false
        startMonitoringSwitch.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !CircularRegion.isMonitoringAvailableForClass() || !self.regionManager.locationServicesEnabled() || self.regionManager.authorizationStatus() == .denied {
            createRegionButton.isEnabled = false
            createRegionButton.setTitleColor(UIColor.lightGray, for: UIControlState())
            var message = "Region monitoring not availble"
            if !regionManager.locationServicesEnabled() {
                message = "Location services not enabled"
            } else if regionManager.authorizationStatus() == .denied {
                message = "Autorization status is denied"
            }
            self.present(UIAlertController.alertOnErrorWithMessage(message), animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func createRegion(_ sender: AnyObject) {
        self.progressView.show()
        let addressFuture = locationManager.startUpdatingLocation(authorization: .authorizedAlways, capacity: 10).flatMap { [unowned self] locations -> Future<[CLPlacemark]> in
            self.locationManager.stopUpdatingLocation()
            if let location = locations.first {
                self.latituteLabel.text = NSString(format: "%.6f", location.coordinate.latitude) as String
                self.longitudeLabel.text = NSString(format: "%.6f", location.coordinate.longitude) as String
                self.region = CircularRegion(center: location.coordinate, radius: 50.0, identifier: "FutureLocation Region", capacity: 10)
            }
            return self.locationManager.reverseGeocodeLocation()
        }
        addressFuture.onSuccess { [unowned self] placemarks in
            if let placemark = placemarks.first {
                self.startMonitoringSwitch.isEnabled = true
                self.startMonitoringLabel.textColor = UIColor.black
                self.progressView.remove()
                if let subThoroughfare = placemark.subThoroughfare, let thoroughfare = placemark.thoroughfare {
                    self.address1Label.text = "\(subThoroughfare) \(thoroughfare)"
                }
                if let subLocality = placemark.subLocality {
                    self.address2Label.text = "\(subLocality)"
                }
                if let subAdministrativeArea = placemark.subAdministrativeArea, let administrativeArea = placemark.administrativeArea {
                    self.address3Label.text = "\(subAdministrativeArea), \(administrativeArea)"
                }
            }
        }
        addressFuture.onFailure { [unowned self] error in
            self.progressView.remove()
            self.present(UIAlertController.alertOnError(error), animated: true, completion: nil)
        }
    }
    
    @IBAction func toggleMonitoring(_ sender: AnyObject) {
        if let region = self.region {
            if self.regionManager.isMonitoring {
                self.regionManager.stopMonitoringAllRegions()
                self.setNotMonitoring(region)
            } else {
                self.startMonitoring(region)
            }
        }
    }
    
    func startMonitoring(_ region: CircularRegion) {
        let regionFuture = regionManager.startMonitoring(for: region, authorization: .authorizedAlways)
        regionFuture.onSuccess { state in
            Notify.withMessage("region Event '\(region.identifier)'")
            switch state {
            case .start:
                self.setStartedMonitoring(region)
                if let region = self.region {
                    self.locationInRegion(region)
                }
            case .inside:
                self.setInsideRegion(region)
            case .outside:
                self.setOutsideRegion(region)
            case .unknown:
                break
            }
        }
        regionFuture.onFailure { error in
            self.startMonitoringSwitch.isOn = false
            Notify.withMessage("Error: '\(error.localizedDescription)'")
        }
    }
    
    func locationInRegion(_ region: CircularRegion) {
        let locationFuture = self.locationManager.startUpdatingLocation(authorization: .authorizedAlways, capacity: 10)
        locationFuture.onSuccess { locations in
            if let location = locations.first {
                self.locationManager.stopUpdatingLocation()
                if region.containsCoordinate(location.coordinate) {
                    self.setInsideRegion(region)
                } else {
                    self.setOutsideRegion(region)
                }
            }
        }
        locationFuture.onFailure { error in
            self.present(UIAlertController.alertOnError(error), animated: true)
        }

    }
    
    func setNotMonitoring(_ region: CircularRegion) {
        self.stateLabel.text = "Not Monitoring"
        self.stateLabel.textColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Not Monitoring '\(region.identifier)'")
    }

    func setStartedMonitoring(_ region: CircularRegion) {
        self.stateLabel.text = "Started Monitoring"
        self.stateLabel.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.6, alpha: 1.0)
        Notify.withMessage("Started monitoring region '\(region.identifier)'")
    }

    func setInsideRegion(_ region: CircularRegion) {
        self.stateLabel.text = "Inside Region"
        self.stateLabel.textColor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Entered region '\(region.identifier)'")
    }

    func setOutsideRegion(_ region: CircularRegion) {
        self.stateLabel.text = "Outside Region"
        self.stateLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.0, alpha: 1.0)
        Notify.withMessage("Exited region '\(region.identifier)'")
    }

}

