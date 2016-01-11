//
//  SignificantChangeInLocationManager.swift
//  FutureLocation
//
//  Created by Troy Stribling on 1/10/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation
import CoreLocation

public protocol SignificantChangeInLocationManagerInjectable {
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
}

public class SignificantChangeInLocationManager : NSObject,  CLLocationManagerDelegate {

    public func locationManager(manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        Logger.debug()
    }

    public func locationManager(_:CLLocationManager, didFailWithError error:NSError) {
        Logger.debug("error \(error.localizedDescription)")
    }

    public func locationManager(_:CLLocationManager, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        Logger.debug("status: \(status)")
    }
}