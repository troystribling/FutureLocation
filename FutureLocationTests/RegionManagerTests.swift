//
//  RegionManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/29/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreLocation
import FutureLocation

class RegionManagerTests: XCTestCase {

    let testCLRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 37.760412, longitude: -122.414602),
                                        radius: 100.0, identifier: "Test Region")

    var testRegion: Region!
    var mock: CLLocationManagerMock!
    var regionManager: RegionManagerUT!

    override func setUp() {
        super.setUp()
        self.testRegion = Region(region: self.testCLRegion)
        self.mock = CLLocationManagerMock()
        self.regionManager = RegionManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testStartMonitoringRegionSuccess() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) {state in
            XCTAssert(state == .Start, "region state invalid")
            XCTAssert(self.mock.startMonitoringForRegionCalled, "startMonitoringForRegion not called")
            expectation.fulfill()
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartMonitoringRegionFailure() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) {error in
            XCTAssert(self.mock.startMonitoringForRegionCalled, "startMonitoringForRegion not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(self.regionManager.regions.count, 1, "Region count invalid")
            expectation.fulfill()
        }
        self.regionManager.monitoringDidFailForRegion(self.testCLRegion, withError: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartMonitoringAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways)
        future.onSuccess {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssertEqual(error.code, LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            XCTAssertFalse(self.mock.startMonitoringForRegionCalled, "startMonitoringForRegion called")
            XCTAssertEqual(self.regionManager.regions.count, 0, "Region count invalid")
            expectation.fulfill()
        }
        self.regionManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDidEnterRegion() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) {state in
            if state == .Start {
                dispatch_async(dispatch_get_main_queue()) { self.regionManager.didEnterRegion(self.testCLRegion) }
            } else {
                XCTAssert(state == .Inside, "region state invalid")
                expectation.fulfill()
            }
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDidExitRegion() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) {state in
            if state == .Start {
                dispatch_async(dispatch_get_main_queue()) { self.regionManager.didExitRegion(self.testCLRegion) }
            } else {
                XCTAssert(state == .Outside, "region state invalid")
                expectation.fulfill()
            }
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.regionManager.didStartMonitoringForRegion(self.testCLRegion)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
