//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK: - RegionManager -
public class RegionManager : LocationManager {

    // MARK: Properties
    internal var regionMonitorStatus = [String: Bool]()
    internal var configuredRegions: [String: Region] = [:]

    // MARK: Configure
    public var maximumRegionMonitoringDistance: CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }

    public var regions: [Region] {
        return LocationManagerIO.queue.sync {
            return Array(self.configuredRegions.values)
        }
    }

    public func region(identifier: String) -> Region? {
        return self.configuredRegions[identifier]
    }

    public override init() {
        super.init()
    }

    // MARK: Control
    public var isMonitoring : Bool {
        return Array(self.regionMonitorStatus.values).filter{$0}.count > 0
    }

    public func isMonitoringRegion(identifier: String) -> Bool {
        return self.regionMonitorStatus[identifier] ?? false
    }

    public func startMonitoringForRegion(region: Region, authorization: CLAuthorizationStatus = .AuthorizedWhenInUse) -> FutureStream<RegionState> {
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.regionMonitorStatus[region.identifier] = true
            self.configuredRegions[region.identifier] = region
            self.clLocationManager.startMonitoringForRegion(region.clRegion)
        }
        authoriztaionFuture.onFailure {error in
            region.regionPromise.failure(error)
        }
        return region.regionPromise.future
    }

    public func stopMonitoringForRegion(region: Region) {
        LocationManagerIO.queue.sync {
            self.regionMonitorStatus.removeValueForKey(region.identifier)
            self.configuredRegions.removeValueForKey(region.identifier)
            self.clLocationManager.stopMonitoringForRegion(region.clRegion)
        }
    }

    public func stopMonitoringAllRegions() {
        for region in self.regions {
            self.stopMonitoringForRegion(region)
        }
    }

    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        LocationManagerIO.queue.sync {
            if let flRegion = self.configuredRegions[region.identifier] {
                flRegion.regionPromise.success(.Inside)
            }
        }
    }
    
    public func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        LocationManagerIO.queue.sync {
            if let flRegion = self.configuredRegions[region.identifier] {
                flRegion.regionPromise.success(.Outside)
            }
        }
    }
    
    public func locationManager(_: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
    }
    
    public func locationManager(_:CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error:NSError) {
        LocationManagerIO.queue.sync {
            if let region = region, flRegion = self.configuredRegions[region.identifier] {
                Logger.debug("region identifier \(region.identifier)")
                flRegion.regionPromise.failure(error)
            }
        }
    }
    
    public func locationManager(_: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        LocationManagerIO.queue.sync {
            if let flRegion = self.configuredRegions[region.identifier] {
                flRegion.regionPromise.success(.Start)
            }
        }
    }
}
