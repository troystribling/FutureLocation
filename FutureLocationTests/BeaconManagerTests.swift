//
//  BeaconManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/29/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreLocation
import FutureLocation

class BeaconManagerTests: XCTestCase {

    let testCLBeaconRegion = CLBeaconRegion(proximityUUID: NSUUID(), major: 1, minor: 2, identifier: "Test Beaccon")
    let testCLBeacons = [
        CLBeaconMock(proximityUUID: NSUUID(), major: 1, minor: 2, proximity: .Immediate, accuracy: kCLLocationAccuracyBest, rssi: -45), CLBeaconMock(proximityUUID: NSUUID(), major: 1, minor: 2, proximity: .Far, accuracy: kCLLocationAccuracyBest, rssi: -85)]

    var testBeaconRegion: BeaconRegion!
    var mock: CLLocationManagerMock!
    var beaconManager: BeaconManagerUT!

    override func setUp() {
        super.setUp()
        self.testBeaconRegion = BeaconRegion(region: self.testCLBeaconRegion)
        self.mock = CLLocationManagerMock()
        self.beaconManager = BeaconManagerUT(clLocationManager: self.mock)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testStartRangingRegionSuccess() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion, context: context)
        future.onSuccess(context) {beacons in
            XCTAssertEqual(beacons.count, 2, "Beacon count invalid")
            XCTAssertEqual(self.beaconManager.beaconRegions.count, 1, "BeaconRegion count invalid")
            XCTAssertEqual(self.beaconManager.regions.count, 1, "Region count invalid")
            XCTAssertEqual(self.testBeaconRegion.beacons.count, 2, "Region Beacon count invalid")
            XCTAssert(self.mock.startRangingBeaconsInRegionCalled, "startRangingBeaconsInRegion not called")
            expectation.fulfill()
        }
        future.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.beaconManager.didRangeBeacons(self.testCLBeacons.map{$0 as CLBeaconInjectable}, inRegion: self.testCLBeaconRegion)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartRangingRegionFailure() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let context = ImmediateContext()
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion, context: context)
        future.onSuccess(context) {beacons in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) {error in
            XCTAssert(self.mock.startRangingBeaconsInRegionCalled, "startRangingBeaconsInRegion not called")
            XCTAssertEqual(self.testBeaconRegion.beacons.count, 0, "Region Beacon count invalid")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            expectation.fulfill()
        }
        self.beaconManager.rangingBeaconsDidFailForRegion(self.testCLBeaconRegion, withError: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartRangingAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.beaconManager.startRangingBeaconsInRegion(self.testBeaconRegion)
        future.onSuccess {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssertEqual(error.code, LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            XCTAssertFalse(self.mock.startRangingBeaconsInRegionCalled, "startRangingBeaconsInRegion not called")
            XCTAssertEqual(self.testBeaconRegion.beacons.count, 0, "Region Beacon count invalid")
            expectation.fulfill()
        }
        self.beaconManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }    

}
