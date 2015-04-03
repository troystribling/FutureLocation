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

    @IBOutlet var latituteLabel      : UILabel!
    @IBOutlet var longitudeLabel     : UILabel!
    @IBOutlet var address1Label      : UILabel!
    @IBOutlet var address2Label      : UILabel!
    @IBOutlet var address3Label      : UILabel!
    @IBOutlet var getAddressButton   : UIButton!
    @IBOutlet var startUpdatesButton : UIButton!
    
    var locationFuture  : FutureStream<[CLLocation]>?
    var addressFuture   : FutureStream<[CLPlacemark]>?
    
    var locationManager = LocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func setLocation(sender:AnyObject) {
        if LocationManager.locationServicesEnabled() {
            let addressManager = LocationManager()
            self.addressFuture = addressManager.startUpdatingLocation(10, authorization:.AuthorizedWhenInUse).flatmap {_ -> Future<[CLPlacemark]> in
                addressManager.stopUpdatingLocation()
                return addressManager.reverseGeocodeLocation()
            }
            self.addressFuture?.onSuccess {placemarks in
                if let placemark = placemarks.first {
                    if let subThoroughfare = placemark.subThoroughfare, thoroughfare = placemark.thoroughfare {
                        self.address1Label.text = "\(subThoroughfare) \(thoroughfare)"
                    } else {
                        self.address1Label.text = "1 Main St"
                    }
                    if let subLocality = placemark.subLocality {
                        self.address2Label.text = "\(placemark.subLocality)"
                    } else {
                        self.address2Label.text = "Meat Packing District"
                    }
                    if let subAdministrativeArea = placemark.subAdministrativeArea, administrativeArea = placemark.administrativeArea {
                        self.address3Label.text = "\(subAdministrativeArea), \(administrativeArea)"
                    } else {
                        self.address3Label.text = "Mt. Juliet, TN"
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

}

