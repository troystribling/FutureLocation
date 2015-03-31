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

class ViewController: UIViewController {

    @IBOutlet var latituteLabel     : UILabel!
    @IBOutlet var longitudeLabel    : UILabel!
    @IBOutlet var address1Label     : UILabel!
    @IBOutlet var address2Label     : UILabel!
    @IBOutlet var address3Label     : UILabel!
    @IBOutlet var getAddressButton  : UIButton!
    
    var locationFuture : FutureStream<[CLLocation]>?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if LocationManager.locatio
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func getAddress(sender:AnyObject) {
    }
}

