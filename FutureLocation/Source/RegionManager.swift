//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

extension CLRegionState: CustomStringConvertible {
 
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .inside:
            return "inside"
        case .outside:
            return "outside"
        }
    }
}

// MARK: - RegionManager -
public class RegionManager : LocationManager {

    // MARK: Serialized Properties
    internal var regionMonitorStatus = [String : Bool]()
    internal var configuredRegions = [String : Region]()
    fileprivate var requestStateForRegionPromises = [String : Promise<CLRegionState>]()

     public fileprivate(set) var isMonitoring = false

    // MARK: Configure
    public var maximumRegionMonitoringDistance: CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }

    public var regions: [Region] {
        return Array(self.configuredRegions.values)
    }

    public func region(_ identifier: String) -> Region? {
        return self.configuredRegions[identifier]
    }

    //MARK: Initialize
    public convenience init() {
        self.init(clLocationManager: CLLocationManager())
    }

    public override init(clLocationManager: CLLocationManagerInjectable) {
        super.init(clLocationManager: clLocationManager)
    }

    // MARK: Control
    public func isMonitoringRegion(_ identifier: String) -> Bool {
        return self.regionMonitorStatus[identifier] ?? false
    }

    public func startMonitoring(for region: Region, authorization: CLAuthorizationStatus = .authorizedWhenInUse, capacity: Int = Int.max, context: ExecutionContext = QueueContext.main) -> FutureStream<RegionState> {
        let authorizationFuture = self.authorize(authorization, context: context)
        authorizationFuture.onFailure { _ in self.updateIsMonitoring(false) }
        return authorizationFuture.flatMap(capacity: capacity, context: context) {
            self.updateIsMonitoring(true)
            self.configuredRegions[region.identifier] = region
            self.clLocationManager.startMonitoring(for: region.clRegion)
            return region.regionPromise.stream
        }
    }

    public func stopMonitoring(for region: Region) {
        self.regionMonitorStatus.removeValue(forKey: region.identifier)
        self.configuredRegions.removeValue(forKey: region.identifier)
        self.clLocationManager.stopMonitoring(for: region.clRegion)
        self.updateIsMonitoring(false)
    }

    public func stopMonitoringAllRegions() {
        for region in self.regions {
            self.stopMonitoring(for: region)
        }
    }

    public func requestState(for region: Region) -> Future<CLRegionState> {
        self.requestStateForRegionPromises[region.identifier] = Promise<CLRegionState>()
        self.clLocationManager.requestState(for: region.clRegion)
        return self.requestStateForRegionPromises[region.identifier]!.future
    }

    // MARK: CLLocationManagerDelegate
    public func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
        self.didEnter(region: region)
    }
    
    public func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
        self.didExit(region: region)
    }
    
    public func locationManager(_: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        self.didDetermine(state: state, forRegion: region)
    }
    
    public func locationManager(_:CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: Error) {
        self.monitoringDidFail(forRegion: region, withError: error)
    }
    
    public func locationManager(_: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        self.didStartMonitoring(forRegion: region)
    }

    public func didEnter(region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.configuredRegions[region.identifier]?.regionPromise.success(.inside)
    }

    public func didExit(region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.configuredRegions[region.identifier]?.regionPromise.success(.outside)
    }

    public func didDetermine(state: CLRegionState, forRegion region: CLRegion) {
        Logger.debug("state '\(state)' region identifier '\(region.identifier)'")
        self.requestStateForRegionPromises[region.identifier]?.success(state)
        self.requestStateForRegionPromises.removeValue(forKey: region.identifier)
    }

    public func monitoringDidFail(forRegion region: CLRegion?, withError error: Error) {
        if let region = region, let flRegion = self.configuredRegions[region.identifier] {
            Logger.debug("region identifier '\(region.identifier)'")
            self.regionMonitorStatus[region.identifier] = false
            flRegion.regionPromise.failure(error)
        }
    }

    public func didStartMonitoring(forRegion region: CLRegion) {
        Logger.debug("region identifier \(region.identifier)")
        self.regionMonitorStatus[region.identifier] = true
        self.configuredRegions[region.identifier]?.regionPromise.success(.start)
    }

    // MARK: Utilities
    func updateIsMonitoring(_ value: Bool) {
        let regionCount = Array(self.regionMonitorStatus.values).filter{$0}.count
        if value {
            self.isMonitoring = true
        } else {
            if regionCount == 0 {
                self.isMonitoring = false
            }
        }
    }

}

