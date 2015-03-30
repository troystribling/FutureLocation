//
//  RegionManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/29/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreLocation
import FutureLocation

class RegionManagerTests: XCTestCase {

    // LocationManagerMock
    class LocationManagerMock : LocationManagerWrappable {
        
        var impl = RegionManagerImpl<RegionManagerMock>()
        
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

    class CLLocationMock : CLLocationWrappable {
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

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStartMonitoringRegionSuccess() {
        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startMonitoringForRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, region:RegionMock(identifier:"region"))
        future.onSuccess {state in
            XCTAssert(state == .Start, "region state invalid")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartMonitoringRegionFailure() {
        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways, error:TestFailure.error)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startMonitoringForRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, region:RegionMock(identifier:"region"))
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
    
    func testStartMonitoringAuthorizationFailure() {
        let mock = RegionManagerMock(responseAuthorization:.Denied)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startMonitoringForRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, region:RegionMock(identifier:"region"))
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
    
    func testDidEnterRegion() {
        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let region = RegionMock(identifier:"region")
        let future = mock.impl.startMonitoringForRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, region:region)
        future.onSuccess {state in
            if state == .Start {
                mock.impl.didEnterRegion(region)
            } else {
                XCTAssert(state == .Inside, "region state invalid")
                expectation.fulfill()
            }
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDidExitRegion() {        
        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let region = RegionMock(identifier:"region")
        let future = mock.impl.startMonitoringForRegion(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways, region:region)
        future.onSuccess {state in
            if state == .Start {
                mock.impl.didExitRegion(region)
            } else {
                XCTAssert(state == .Outside, "region state invalid")
                expectation.fulfill()
            }
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
