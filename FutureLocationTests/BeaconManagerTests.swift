//
//  BeaconManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/29/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreLocation
import FutureLocation

class BeaconManagerTests: XCTestCase {

    // LocationManagerMock
    class LocationManagerMock : LocationManagerWrappable {
        
        var impl = BeaconManagerImpl<BeaconManagerMock>()

        let responseAuthorization:CLAuthorizationStatus?
        let error : NSError?
        
        var location : CLLocationMock! {
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
        
        func startUpdatingLocation() {
            if let responseAuthorization = self.responseAuthorization {
                if let error = self.error {
                    self.impl.didFailWithError(error)
                } else {
                    self.impl.didUpdateLocations([CLLocationMock(), CLLocationMock()])
                }
            }
        }
        
        func stopUpdatingLocation() {
        }
    }
    //LocationManagerMock
    //RegionManagerMock
    class RegionManagerMock : LocationManagerMock, RegionManagerWrappable {
        
        // RegionManagerWrappable
        var _regions = [String:RegionMock]()
        
        var regions : [RegionMock] {
            return self._regions.values.array
        }
        
        func region(identifier:String) -> RegionMock? {
            return self._regions[identifier]
        }
        
        func wrappedStartMonitoringForRegion(region:RegionMock) {
            self._regions[region.identifier] = region
            if let responseAuthorization = self.responseAuthorization {
                if let error = self.error {
                    self.impl.didFailMonitoringForRegion(region, error:error)
                } else {
                    self.impl.didStartMonitoringForRegion(region)
                }
            }
        }
        
        func wrappedStopMonitoringForRegion(region:RegionMock) {
            self._regions.removeValueForKey(region.identifier)
        }
        
    }
    // RegionManagerMock
    class BeaconManagerMock : RegionManagerMock, BeaconManagerWrappable {

        var _beaconRegions = [BeaconRegionMock]()

        var beaconRegions : [BeaconRegionMock] {
            return self.beaconRegions
        }
        
        func wrappedStartRangingBeaconsInRegion(beaconRegion:BeaconRegionMock) {
            if let responseAuthorization = self.responseAuthorization {
                if let error = self.error {
                    self.impl.didFailRangingBeaconsForRegion(beaconRegion, error:error)
                } else {
                    self.impl.didRangeBeacons([BeaconMock(), BeaconMock()], region:beaconRegion)
                }
            }
        }
        
        func wrappedStopRangingBeaconsInRegion(beaconRegion:BeaconRegionMock) {
        }
        
    }
    
    class CLLocationMock : CLLocationWrappable {
    }
    
    // RegionMock
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
    // RegionMock
    // BeaconRegionMock
    class BeaconRegionMock : RegionMock, BeaconRegionWrappable {
        
        let _beaconPromise = StreamPromise<[BeaconMock]>()
        
        var beaconPromise : StreamPromise<[BeaconMock]> {
            return self._beaconPromise
        }
        
        func peripheralDataWithMeasuredPower(measuredPower:Int?) -> [NSObject:AnyObject] {
            return [:]
        }
    }
    class BeaconMock : BeaconWrappable {
        
    }
    // BeaconRegionMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testStartRangingRegionSuccess() {
        let mock = BeaconManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startRangingBeaconsInRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, beaconRegion:BeaconRegionMock(identifier:"region"))
        future.onSuccess {beacons in
            XCTAssert(beacons.count == 2, "region state invalid")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartRangingRegionFailure() {
        let mock = BeaconManagerMock(responseAuthorization:.AuthorizedAlways, error:TestFailure.error)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startRangingBeaconsInRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, beaconRegion:BeaconRegionMock(identifier:"region"))
        future.onSuccess {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartRangingAuthorizationFailure() {
        let mock = BeaconManagerMock(responseAuthorization:.Denied)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startRangingBeaconsInRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, beaconRegion:BeaconRegionMock(identifier:"region"))
        future.onSuccess {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }    
}
