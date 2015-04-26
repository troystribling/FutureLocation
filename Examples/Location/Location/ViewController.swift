//
//  ViewController.swift
//  Location
//
//  Created by Troy Stribling on 3/30/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreLocation
import FutureLocation

class ViewController: UITableViewController {

    @IBOutlet var latituteLabel      : UILabel!
    @IBOutlet var longitudeLabel     : UILabel!
    @IBOutlet var address1Label      : UILabel!
    @IBOutlet var address2Label      : UILabel!
    @IBOutlet var address3Label      : UILabel!
    @IBOutlet var getAddressButton   : UIButton!
    @IBOutlet var startUpdatesSwitch : UISwitch!
    @IBOutlet var startUpdatesLabel  : UILabel!
    
    let locationManager = LocationManager()
    let addressManager  = LocationManager()
    
    let progressView = ProgressView()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !LocationManager.locationServicesEnabled() || LocationManager.authorizationStatus() == .Denied {
            self.startUpdatesLabel.textColor = UIColor.lightGrayColor()
            self.startUpdatesSwitch.enabled = false
            self.getAddressButton.enabled = false
            var message = "Location services disabled"
            if LocationManager.authorizationStatus() == .Denied {
                message = "Authorization status is denied"
            }
            self.getAddressButton.setTitleColor(UIColor.lightGrayColor(), forState:UIControlState.Disabled)
            self.presentViewController(UIAlertController.alertOnErrorWithMessage(message), animated:true, completion:nil)
        } else {
            if LocationManager.locationServicesEnabled() {
                if self.locationManager.isUpdating {
                    self.startUpdatesSwitch.on = true
                } else {
                    self.startUpdatesSwitch.on = false
                }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func getAddress(sender:AnyObject) {
        self.progressView.show()
        let addressFuture = self.addressManager.startUpdatingLocation(10, authorization:.AuthorizedWhenInUse).flatmap {_ -> Future<[CLPlacemark]> in
                                 self.addressManager.stopUpdatingLocation()
                                 return self.addressManager.reverseGeocodeLocation()
                             }
        addressFuture.onSuccess {placemarks in
            if let placemark = placemarks.first {
                self.progressView.remove()
                if let subThoroughfare = placemark.subThoroughfare, thoroughfare = placemark.thoroughfare {
                    self.address1Label.text = "\(subThoroughfare) \(thoroughfare)"
                }
                if let subLocality = placemark.subLocality {
                    self.address2Label.text = "\(placemark.subLocality)"
                }
                if let subAdministrativeArea = placemark.subAdministrativeArea, administrativeArea = placemark.administrativeArea {
                    self.address3Label.text = "\(subAdministrativeArea), \(administrativeArea)"
                }
            }
        }
        addressFuture.onFailure {error in
            self.progressView.remove()
            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
        }
    }
    
    @IBAction func startUpdatingLocation(sender:AnyObject) {
        if self.locationManager.isUpdating {
            self.locationManager.stopUpdatingLocation()
        } else {
            self.progressView.show()
            let locationFuture = self.locationManager.startUpdatingLocation(10, authorization:.AuthorizedWhenInUse)
            locationFuture.onSuccess {locations in
                if let location = locations.first {
                    self.progressView.remove()
                    self.latituteLabel.text =  NSString(format: "%.6f", location.coordinate.latitude) as String
                    self.longitudeLabel.text = NSString(format: "%.6f", location.coordinate.longitude) as String
                }
            }
            locationFuture.onFailure {error in
                self.progressView.remove()
                self.startUpdatesSwitch.on = false
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
        }
    }
}

