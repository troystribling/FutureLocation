//
//  LocationRegionManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation

/////////////////////////////////////////////
// RegionManagerImpl
public protocol RegionManagerWrappable {
    
    typealias WrappedRegion
    
    var regions : [WrappedRegion] {get}
    
    func region(identifier:String) -> WrappedRegion?
    func startMonitoringForRegion(region:WrappedRegion)
    func stopMonitoringForRegion(region:WrappedRegion)
    
}

public protocol RegionWrappable {
    var regionPromise   : StreamPromise<RegionState> {get}
    var identifier      : String {get}
}

public final class RegionManagerImpl<Wrapper where Wrapper:RegionManagerWrappable,
                                     Wrapper:LocationManagerWrappable,
                                     Wrapper.WrappedCLLocation:CLLocationWrappable,
                                     Wrapper.WrappedRegion:RegionWrappable> : LocationManagerImpl<Wrapper> {
    
    internal var regionMonitorStatus = [String:Bool]()
    
    public var isMonitoring : Bool {
        return self.regionMonitorStatus.values.array.any{$0}
    }
    
    public override init() {
    }
    
    public func isMonitoringRegion(identifier:String) -> Bool {
        if let status = self.regionMonitorStatus[identifier] {
            return status
        } else {
            return false
        }
    }
    
    // control
    public func startMonitoringForRegion(manager:Wrapper, authorization:CLAuthorizationStatus, region:Wrapper.WrappedRegion) -> FutureStream<RegionState> {
        let authoriztaionFuture = self.authorize(manager, authorization:authorization)
        authoriztaionFuture.onSuccess {status in
            self.regionMonitorStatus[region.identifier] = true
            manager.startMonitoringForRegion(region)
        }
        authoriztaionFuture.onFailure {error in
            region.regionPromise.failure(error)
        }
        return region.regionPromise.future
    }
    
    public func startMonitoringForRegion(manager:Wrapper, region:Wrapper.WrappedRegion) -> FutureStream<RegionState> {
        return self.startMonitoringForRegion(manager, authorization:CLAuthorizationStatus.AuthorizedAlways, region:region)
    }
    
    public func stopMonitoringForRegion(manager:Wrapper, region:Wrapper.WrappedRegion) {
        self.regionMonitorStatus.removeValueForKey(region.identifier)
        manager.stopMonitoringForRegion(region)
    }
    
    public func resumeMonitoringAllRegions(manager:Wrapper) {
        for region in manager.regions {
            self.regionMonitorStatus[region.identifier] = true
            manager.startMonitoringForRegion(region)
        }
    }
    
    public func pauseMonitoringAllRegions(manager:Wrapper) {
        for region in manager.regions {
            self.regionMonitorStatus[region.identifier] = false
            manager.stopMonitoringForRegion(region)
        }
    }
    
    public func stopMonitoringAllRegions(manager:Wrapper) {
        for region in manager.regions {
            manager.stopMonitoringForRegion(region)
        }
    }
    
    // CLLocationManagerDelegate
    public func didEnterRegion(region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didEnterRegion: \(region.identifier)")
        region.regionPromise.success(.Inside)
    }
    
    public func didExitRegion(region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didExitRegion: \(region.identifier)")
        region.regionPromise.success(.Outside)
    }
    
    public func didDetermineState(state:CLRegionState, forRegion region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didDetermineState: \(region.identifier)")
    }
    
    public func monitoringDidFailForRegion(region:Wrapper.WrappedRegion, withError error:NSError!) {
        Logger.debug("RegionManagerImpl#monitoringDidFailForRegion: \(region.identifier)")
        region.regionPromise.failure(error)
    }
    
    public func didStartMonitoringForRegion(region:Wrapper.WrappedRegion) {
        Logger.debug("RegionManagerImpl#didStartMonitoringForRegion: \(region.identifier)")
        region.regionPromise.success(.Start)
    }
}

// RegionManagerImpl
/////////////////////////////////////////////

public class RegionManager : LocationManager {

    internal var configuredRegions       : [CLRegion:Region] = [:]
    internal var regionMonitorStatus     : [String:Bool]     = [:]
    
    public var regions : [Region] {
        return self.configuredRegions.values.array
    }
    
    public var maximumRegionMonitoringDistance : CLLocationDistance {
        return self.clLocationManager.maximumRegionMonitoringDistance
    }
    
    public var isMonitoring : Bool {
        return self.regionMonitorStatus.values.array.any{$0}
    }
    
    public class var sharedInstance : RegionManager {
        struct Static {
            static let instance = RegionManager()
        }
        return Static.instance
    }
    
    public override init() {
        super.init()
    }
    
    public func isMonitoringRegion(identifier:String) -> Bool {
        if let status = self.regionMonitorStatus[identifier] {
            return status
        } else {
            return false
        }
    }
    
    public func region(identifier:String) -> Region? {
        let regions = self.configuredRegions.keys.array.filter{$0.identifier == identifier}
        if let region = regions.first {
            return self.configuredRegions[region]
        } else {
            return nil
        }
    }

    // control
    public func startMonitoringForRegion(authorization:CLAuthorizationStatus, region:Region) -> FutureStream<RegionState> {
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.regionMonitorStatus[region.identifier] = true
            self.configuredRegions[region.clRegion] = region
            self.clLocationManager.startMonitoringForRegion(region.clRegion)
        }
        authoriztaionFuture.onFailure {error in
            region.regionPromise.failure(error)
        }
        return region.regionPromise.future
    }

    public func startMonitoringForRegion(region:Region) -> FutureStream<RegionState> {
        return self.startMonitoringForRegion(CLAuthorizationStatus.AuthorizedAlways, region:region)
    }

    public func stopMonitoringForRegion(region:Region) {
        self.regionMonitorStatus.removeValueForKey(region.identifier)
        self.configuredRegions.removeValueForKey(region.clRegion)
        self.clLocationManager.stopMonitoringForRegion(region.clRegion)
    }
    
    public func resumeMonitoringAllRegions() {
        for region in self.regions {
            self.regionMonitorStatus[region.identifier] = true
            self.clLocationManager.startMonitoringForRegion(region.clRegion)
        }
    }
    
    public func pauseMonitoringAllRegions() {
        for region in self.regions {
            self.regionMonitorStatus[region.identifier] = false
            self.clLocationManager.stopMonitoringForRegion(region.clRegion)
        }
    }

    public func stopMonitoringAllRegions() {
        for region in self.regions {
            self.stopMonitoringForRegion(region)
        }
    }

    // CLLocationManagerDelegate
    public func locationManager(_:CLLocationManager!, didEnterRegion region:CLRegion!) {
        Logger.debug("RegionManager#didEnterRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            bcregion.regionPromise.success(.Inside)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didExitRegion region:CLRegion!) {
        Logger.debug("RegionManager#didExitRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            bcregion.regionPromise.success(.Outside)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didDetermineState state:CLRegionState, forRegion region:CLRegion!) {
        Logger.debug("RegionManager#didDetermineState: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
        }
    }
    
    public func locationManager(_:CLLocationManager!, monitoringDidFailForRegion region:CLRegion!, withError error:NSError!) {
        Logger.debug("RegionManager#monitoringDidFailForRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            bcregion.regionPromise.failure(error)
        }
    }
    
    public func locationManager(_:CLLocationManager!, didStartMonitoringForRegion region:CLRegion!) {
        Logger.debug("RegionManager#didStartMonitoringForRegion: \(region.identifier)")
        if let bcregion = self.configuredRegions[region] {
            bcregion.regionPromise.success(.Start)
        }
    }
}
