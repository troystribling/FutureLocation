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

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStartMonitoringRegionSuccess() {
        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:RegionMock(identifier:"region"))
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
        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:RegionMock(identifier:"region"))
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
        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:RegionMock(identifier:"region"))
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
        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:region)
        future.onSuccess {state in
            if state == .Start {
                mock.regionImpl.didEnterRegion(region)
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
        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:region)
        future.onSuccess {state in
            if state == .Start {
                mock.regionImpl.didExitRegion(region)
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
