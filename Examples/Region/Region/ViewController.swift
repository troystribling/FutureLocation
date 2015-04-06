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

class ViewController: UITableViewController {

    @IBOutlet var stateLabel            : UILabel!
    @IBOutlet var latituteLabel         : UILabel!
    @IBOutlet var longitudeLabel        : UILabel!
    @IBOutlet var address1Label         : UILabel!
    @IBOutlet var address2Label         : UILabel!
    @IBOutlet var address3Label         : UILabel!
    @IBOutlet var startMonitoringSwitch : UISwitch!
    @IBOutlet var createRegionButton    : UIButton!
    
    var region          : CircularRegion?
    var regionFuture    : FutureStream<RegionState>?
    var addressFuture   : FutureStream<[CLPlacemark]>?
    
    let addressManager  = LocationManager()
    let regionManager   = RegionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func createRegion(sender:AnyObject) {
        if LocationManager.locationServicesEnabled() {
            self.addressFuture = self.addressManager.startUpdatingLocation(10, authorization:.AuthorizedAlways).flatmap {locations -> Future<[CLPlacemark]> in
                self.addressManager.stopUpdatingLocation()
                if let location = locations.first {
                    self.latituteLabel.text = NSString(format: "%.6f", location.coordinate.latitude) as String
                    self.longitudeLabel.text = NSString(format: "%.6f", location.coordinate.longitude) as String
                    self.startMonitoringSwitch.enabled = true
                    self.region = CircularRegion(center:location.coordinate, identifier:"FutureLocation Region", capacity:10)
                }
                return self.addressManager.reverseGeocodeLocation()
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
    
    @IBAction func toggleMonitoring(sender:AnyObject) {
        if let region = self.region {
            if self.regionManager.isMonitoring {
                self.regionManager.stopMonitoringAllRegions()
                self.stateLabel.text = "Not Monitoring"
                self.stateLabel.textColor = UIColor(red:0.6, green:0.0, blue:0.0, alpha:1.0)
                Notify.withMessage("Not Monitoring '\(region.identifier)'")
            } else {
                self.startMonitoring(region)
            }
        }
    }
    
    func startMonitoring(region:CircularRegion) {
        self.regionFuture = self.regionManager.startMonitoringForRegion(region, authorization:.AuthorizedAlways)
        self.regionFuture?.onSuccess {state in
            switch state {
            case .Start:
                self.stateLabel.text = "Started Monitoring"
                self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
                Notify.withMessage("Started monitoring region '\(region.identifier)'")
            case .Inside:
                self.stateLabel.text = "Inside Region"
                self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
                Notify.withMessage("Entered region '\(region.identifier)'")
            case .Outside:
                self.stateLabel.text = "Outside Region"
                self.stateLabel.textColor = UIColor(red:0.0, green:0.6, blue:0.0, alpha:1.0)
                Notify.withMessage("Exited region '\(region.identifier)'")
            }
        }
        self.regionFuture?.onFailure {error in
            Notify.withMessage("Error: '\(error.localizedDescription)'")
        }
    }

}

