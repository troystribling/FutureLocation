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

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testStartRangingRegionSuccess() {
        let mock = BeaconManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.beaconImpl.startRangingBeaconsInRegion(mock, authorization:.AuthorizedAlways, beaconRegion:BeaconRegionMock(identifier:"region"))
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
        let future = mock.beaconImpl.startRangingBeaconsInRegion(mock, authorization:.AuthorizedAlways, beaconRegion:BeaconRegionMock(identifier:"region"))
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
        let future = mock.beaconImpl.startRangingBeaconsInRegion(mock, authorization:.AuthorizedAlways, beaconRegion:BeaconRegionMock(identifier:"region"))
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
