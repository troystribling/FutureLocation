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

// LocationManagerMock
class LocationManagerMock : LocationManagerWrappable {
    
    var impl = LocationManagerImpl<LocationManagerMock>()
    
    let responseAuthorization:CLAuthorizationStatus?
    let error : NSError?
    
    var location : CLLocationMock? {
        return CLLocationMock()
    }
    
    init(responseAuthorization:CLAuthorizationStatus? = nil, error:NSError? = nil) {
        self.responseAuthorization = responseAuthorization
        self.error = error
    }
    
    func requestWhenInUseAuthorization() {
        if let responseAuthorization = self.responseAuthorization {
            self.impl.didChangeAuthorizationStatus(responseAuthorization)
        }
    }
    
    func requestAlwaysAuthorization() {
        if let responseAuthorization = self.responseAuthorization {
            self.impl.didChangeAuthorizationStatus(responseAuthorization)
        }
    }
    
    func wrappedStartUpdatingLocation() {
        if let _ = self.responseAuthorization {
            if let error = self.error {
                self.impl.didFailWithError(error)
            } else {
                self.impl.didUpdateLocations([CLLocationMock(), CLLocationMock()])
            }
        }
    }
    
    func wrappedStartMonitoringSignificantLocationChanges() {
        if let _ = self.responseAuthorization {
            if let error = self.error {
                self.impl.didFailWithError(error)
            } else {
                self.impl.didUpdateLocations([CLLocationMock(), CLLocationMock()])
            }
        }
    }
    
    func authorize(requestedAuthorization:CLAuthorizationStatus) -> Future<Void> {
        let promise = Promise<Void>()
        if requestedAuthorization == self.responseAuthorization! {
            promise.success()
        } else {
            promise.failure(FLError.authoizationAlwaysFailed)
        }
        return promise.future
    }

}

class CLLocationMock : CLLocationWrappable {
}
// LocationManagerMock

//RegionManagerMock
class RegionManagerMock : LocationManagerMock, RegionManagerWrappable {
    
    let regionImpl = RegionManagerImpl<RegionManagerMock>()
    
    // RegionManagerWrappable
    var _regions = [String:RegionMock]()
    
    var regions : [RegionMock] {
        return Array(self._regions.values)
    }
    
    func region(identifier:String) -> RegionMock? {
        return self._regions[identifier]
    }
    
    func wrappedStartMonitoringForRegion(region:RegionMock) {
        self._regions[region.identifier] = region
        if let _ = self.responseAuthorization {
            if let error = self.error {
                self.regionImpl.didFailMonitoringForRegion(region, error:error)
            } else {
                self.regionImpl.didStartMonitoringForRegion(region)
            }
        }
    }
    
    func wrappedStopMonitoringForRegion(region:RegionMock) {
        self._regions.removeValueForKey(region.identifier)
    }
    
}

class RegionMock : RegionWrappable {
    
    let _regionPromise = StreamPromise<RegionState>()
    let _identifier : String
    
    var regionPromise   : StreamPromise<RegionState> {
        return self._regionPromise
    }
    
    var identifier : String {
        return self._identifier
    }
    
    init(identifier:String) {
        self._identifier = identifier
    }
    
}
// RegionManagerMock

// BeaconRegionMock
class BeaconManagerMock : RegionManagerMock, BeaconManagerWrappable {
    
    let beaconImpl = BeaconManagerImpl<BeaconManagerMock>()
    
    var _beaconRegions = [BeaconRegionMock]()
    
    var beaconRegions : [BeaconRegionMock] {
        return self.beaconRegions
    }
    
    func wrappedStartRangingBeaconsInRegion(beaconRegion:BeaconRegionMock) {
        if let error = self.error {
            self.beaconImpl.didFailRangingBeaconsForRegion(beaconRegion, error:error)
        } else {
            self.beaconImpl.didRangeBeacons([BeaconMock(), BeaconMock()], region:beaconRegion)
        }
    }
    
    func wrappedStopRangingBeaconsInRegion(beaconRegion:BeaconRegionMock) {
    }
    
}

class BeaconRegionMock : RegionMock, BeaconRegionWrappable {
    
    let _beaconPromise = StreamPromise<[BeaconMock]>()
    
    var beaconPromise : StreamPromise<[BeaconMock]> {
        return self._beaconPromise
    }
    
    func peripheralDataWithMeasuredPower(measuredPower:Int?) -> [String:AnyObject] {
        return [:]
    }
}
class BeaconMock : BeaconWrappable {
    
}
// BeaconRegionMock



