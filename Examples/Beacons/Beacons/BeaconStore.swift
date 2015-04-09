//
//  BeaconStore.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/16/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import FutureLocation

class BeaconStore {
    
    class func getBeacon() -> NSUUID? {
        if let storedBeacon = NSUserDefaults.standardUserDefaults().stringForKey("beacon") {
            return NSUUID(UUIDString:storedBeacon)
        } else {
            return nil
        }
    }
    
    class func setBeacons(uuid:String) {
        NSUserDefaults.standardUserDefaults().setObject(uuid, forKey:"beacon")
    }
    
}