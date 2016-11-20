//
//  ViewController.swift
//  Location
//
//  Created by Troy Stribling on 3/30/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
import FutureLocation

class ViewController: UITableViewController {

    @IBOutlet var latituteLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var address1Label: UILabel!
    @IBOutlet var address2Label: UILabel!
    @IBOutlet var address3Label: UILabel!
    @IBOutlet var getAddressButton: UIButton!
    @IBOutlet var startUpdatesSwitch: UISwitch!
    @IBOutlet var startUpdatesLabel: UILabel!
    
    let locationManager = LocationManager()
    let addressManager  = LocationManager()
    
    let addressProgressView = ProgressView()
    let locationProgressView = ProgressView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !locationManager.locationServicesEnabled() || locationManager.authorizationStatus() == .denied {
            startUpdatesLabel.textColor = UIColor.lightGray
            startUpdatesSwitch.isEnabled = false
            getAddressButton.isEnabled = false
            var message = "Location services disabled"
            if self.locationManager.authorizationStatus() == .denied {
                message = "Authorization status is denied"
            }
            getAddressButton.setTitleColor(UIColor.lightGray, for: UIControlState.disabled)
            present(UIAlertController.alertOnErrorWithMessage(message), animated: true, completion: nil)
        } else {
            if locationManager.locationServicesEnabled() {
                if locationManager.isUpdating {
                    startUpdatesSwitch.isOn = true
                } else {
                    startUpdatesSwitch.isOn = false
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func getAddress(_ sender: AnyObject) {
        self.addressProgressView.show()
        let addressFuture = addressManager.startUpdatingLocation(authorization: .authorizedWhenInUse, capacity: 10).flatMap { [unowned self]  _ -> Future<[CLPlacemark]> in
                                 self.addressManager.stopUpdatingLocation()
                                 return self.addressManager.reverseGeocodeLocation()
                             }
        addressFuture.onSuccess { [unowned self] placemarks in
            if let placemark = placemarks.first {
                self.addressProgressView.remove()
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
            self.addressProgressView.remove()
            self.present(UIAlertController.alertOnError(error), animated: true)
        }
    }
    
    @IBAction func startUpdatingLocation(_ sender: AnyObject) {
        if locationManager.isUpdating {
            locationManager.stopUpdatingLocation()
        } else {
            locationProgressView.show()
            let locationFuture = locationManager.startUpdatingLocation(authorization: .authorizedWhenInUse, capacity: 10)
            locationFuture.onSuccess { [unowned self] locations in
                if let location = locations.first {
                    self.locationProgressView.remove()
                    self.latituteLabel.text =  NSString(format: "%.6f", location.coordinate.latitude) as String
                    self.longitudeLabel.text = NSString(format: "%.6f", location.coordinate.longitude) as String
                }
            }
            locationFuture.onFailure { [unowned self] error in
                self.locationProgressView.remove()
                self.startUpdatesSwitch.isOn = false
                self.present(UIAlertController.alertOnError(error), animated: true)
            }
        }
    }
}

