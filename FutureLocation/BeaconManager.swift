//
//  BeaconManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK - BeaconManager -
public class BeaconManager : RegionManager {

    private var regionRangingStatus = [String:Bool]()
    internal var configuredBeaconRegions: [CLBeaconRegion:BeaconRegion]  = [:]

    public class func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }

    public var beaconRegions: [BeaconRegion] {
        return Array(self.configuredBeaconRegions.values)
    }

    public var isRanging: Bool {
        return Array(self.regionRangingStatus.values).filter{$0}.count > 0
    }
    
    public override init() {
        super.init()
    }

    public func beaconRegion(identifier: String) -> BeaconRegion? {
        let regions = Array(self.configuredBeaconRegions.keys).filter{$0.identifier == identifier}
        if let region = regions.first {
            return self.configuredBeaconRegions[region]
        } else {
            return nil
        }
    }

    public func isRangingRegion(identifier:String) -> Bool {
        if let status = self.regionRangingStatus[identifier] {
            return status
        } else {
            return false
        }
    }

    public func startRangingBeaconsInRegion(beaconRegion:BeaconRegion) -> FutureStream<[Beacon]> {
        let authoriztaionFuture = self.authorize(CLAuthorizationStatus.AuthorizedAlways)
        authoriztaionFuture.onSuccess {status in
            Logger.debug("authorization status: \(status)")
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.configuredBeaconRegions[beaconRegion.clBeaconRegion] = beaconRegion
            self.configuredRegions[beaconRegion.clBeaconRegion] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
        }
        authoriztaionFuture.onFailure {error in
            beaconRegion.beaconPromise.failure(error)
        }
        return beaconRegion.beaconPromise.future

    }

    public func stopRangingBeaconsInRegion(beaconRegion:BeaconRegion) {
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.clBeaconRegion)
        self.configuredRegions.removeValueForKey(beaconRegion.clBeaconRegion)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.stopRangingBeaconsInRegion(beaconRegion)
        }
    }

    public func requestStateForRegion(beaconMonitor:BeaconRegion) {
        self.clLocationManager.requestStateForRegion(beaconMonitor.clRegion)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        Logger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region] {
            let flBeacons = beacons.map{Beacon(clBeacon:$0)}
            beaconRegion._beacons = flBeacons
            beaconRegion.beaconPromise.success(flBeacons)
        }
    }
    
    public func locationManager(_: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
        Logger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region] {
            beaconRegion.beaconPromise.failure(error)
        }
    }
    
}
