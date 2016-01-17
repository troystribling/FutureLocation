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

    // MARK: Properties
    private var regionRangingStatus = SerialDictionary<String, Bool>(LocationManagerIO.queue)
    internal var configuredBeaconRegions = SerialDictionary<String, BeaconRegion>(LocationManagerIO.queue)

    public class func isRangingAvailable() -> Bool {
        return CLLocationManager.isRangingAvailable()
    }

    public var beaconRegions: [BeaconRegion] {
        return self.configuredBeaconRegions.values
    }

    public func beaconRegion(identifier: String) -> BeaconRegion? {
        return self.configuredBeaconRegions[identifier]
    }

    public override init() {
        super.init()
    }

    // MARK: Control
    public var isRanging: Bool {
        return LocationManagerIO.queue.sync { Array(self.regionRangingStatus.values).filter{$0}.count > 0 }
    }

    public func isRangingRegion(identifier:String) -> Bool {
        return self.regionRangingStatus[identifier] ?? false
    }

    public func startRangingBeaconsInRegion(beaconRegion: BeaconRegion) -> FutureStream<[Beacon]> {
        let authoriztaionFuture = self.authorize(CLAuthorizationStatus.AuthorizedAlways)
        authoriztaionFuture.onSuccess {status in
            Logger.debug("authorization status: \(status)")
            self.regionRangingStatus[beaconRegion.identifier] = true
            self.configuredBeaconRegions[beaconRegion.identifier] = beaconRegion
            self.configuredRegions[beaconRegion.identifier] = beaconRegion
            self.clLocationManager.startRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
        }
        authoriztaionFuture.onFailure {error in
            beaconRegion.beaconPromise.failure(error)
        }
        return beaconRegion.beaconPromise.future

    }

    public func stopRangingBeaconsInRegion(beaconRegion: BeaconRegion) {
        self.configuredBeaconRegions.removeValueForKey(beaconRegion.identifier)
        self.configuredRegions.removeValueForKey(beaconRegion.identifier)
        self.clLocationManager.stopRangingBeaconsInRegion(beaconRegion.clBeaconRegion)
    }

    public func stopRangingAllBeacons() {
        for beaconRegion in self.beaconRegions {
            self.stopRangingBeaconsInRegion(beaconRegion)
        }
    }

    public func requestStateForRegion(beaconMonitor: BeaconRegion) {
        self.clLocationManager.requestStateForRegion(beaconMonitor.clRegion)
    }
    
    // CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        Logger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region.identifier] {
            let flBeacons = beacons.map{Beacon(clBeacon:$0)}
            beaconRegion._beacons = flBeacons
            beaconRegion.beaconPromise.success(flBeacons)
        }
    }
    
    public func locationManager(_: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
        Logger.debug("region identifier \(region.identifier)")
        if let beaconRegion = self.configuredBeaconRegions[region.identifier] {
            beaconRegion.beaconPromise.failure(error)
        }
    }
    
}
