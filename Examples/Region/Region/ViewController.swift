//
//  ViewController.swift
//  Region
//
//  Created by Troy Stribling on 4/3/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreLocation
import FutureLocation

class ViewController: UIViewController {

    @IBOutlet var stateLabel            : UILabel!
    @IBOutlet var latituteLabel         : UILabel!
    @IBOutlet var longitudeLabel        : UILabel!
    @IBOutlet var address1Label         : UILabel!
    @IBOutlet var address2Label         : UILabel!
    @IBOutlet var address3Label         : UILabel!
    @IBOutlet var startMonitoringButton : UIButton!
    @IBOutlet var createRegionButton    : UIButton!
    
    var region          : CircularRegion?
    var regionFuture    : FutureStream<RegionState>?
    var addressFuture   : FutureStream<[CLPlacemark]>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func createRegion(sender:AnyObject) {
        if LocationManager.locationServicesEnabled() {
            let addressManager = LocationManager()
            self.addressFuture = addressManager.startUpdatingLocation(10, authorization:.AuthorizedWhenInUse).flatmap {locations -> Future<[CLPlacemark]> in
                addressManager.stopUpdatingLocation()
                if let location = locations.first {
                    self.latituteLabel.text = "\(location.coordinate.latitude)"
                    self.longitudeLabel.text = "\(location.coordinate.longitude)"
                    self.startMonitoringButton.enabled = true
                    self.startMonitoringButton.setTitleColor(UIColor(red:0.0, green:0.7, blue:0.0, alpha:1.0), forState:.Normal)
                    self.region = CircularRegion(center:location.coordinate, identifier:"region", capacity:10)
                }
                return addressManager.reverseGeocodeLocation()
            }
            self.addressFuture?.onSuccess {placemarks in
                if let placemark = placemarks.first {
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
            self.addressFuture?.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
        } else {
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("Location services disabled"), animated:true, completion:nil)
        }
    }
    
    @IBAction func startMonitoring(sender:AnyObject) {
        if let region = self.region {
            
        }
    }

}

