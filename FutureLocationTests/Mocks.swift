//
//  Mocks.swift
//  FutureLocation
//
//  Created by Troy Stribling on 4/12/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
import FutureLocation

//class CLLocationManagerMock : CLLocationManagerInjectable {
//    
//    var delegate: CLLocationManagerDelegate?
//
//    static func authorizationStatus() -> CLAuthorizationStatus
//    func requestAlwaysAuthorization()
//    func requestWhenInUseAuthorization()
//
//    var location: CLLocation? { get }
//
//    var pausesLocationUpdatesAutomatically: Bool { get set }
//    var allowsBackgroundLocationUpdates: Bool { get set}
//    var activityType: CLActivityType { get set }
//    var distanceFilter : CLLocationDistance { get set }
//    var desiredAccuracy: CLLocationAccuracy { get set }
//
//    static func locationServicesEnabled() -> Bool
//    func startUpdatingLocation()
//    func stopUpdatingLocation()
//    func requestLocation()
//
//    static func deferredLocationUpdatesAvailable() -> Bool
//    func allowDeferredLocationUpdatesUntilTraveled(distance: CLLocationDistance, timeout: NSTimeInterval)
//
//    static func significantLocationChangeMonitoringAvailable() -> Bool
//    func startMonitoringSignificantLocationChanges()
//    func stopMonitoringSignificantLocationChanges()
//
//    var monitoredRegions: Set<CLRegion> { get }
//    var maximumRegionMonitoringDistance: CLLocationDistance { get }
//    func startMonitoringForRegion(region: CLRegion)
//    func stopMonitoringForRegion(region: CLRegion)
//
//    static func isRangingAvailable() -> Bool
//    var rangedRegions: Set<CLRegion> { get }
//    func startRangingBeaconsInRegion(region: CLBeaconRegion)
//    func stopRangingBeaconsInRegion(region: CLBeaconRegion)
//    func requestStateForRegion(region: CLRegion)
//
//}

class CLBeaconMock : CLBeaconInjectable {
    let proximityUUID: NSUUID
    let major: NSNumber
    let minor: NSNumber
    let proximity: CLProximity
    let accuracy: CLLocationAccuracy
    let rssi: Int
    init(proximityUUID: NSUUID, major: NSNumber, minor: NSNumber, proximity: CLProximity, accuracy: CLLocationAccuracy, rssi: Int) {
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        self.proximity = proximity
        self.accuracy = accuracy
        self.rssi = rssi
    }
}



