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
    var testRegion: Region {
        return Region(region: self.testCLRegion)
    }

    var mock: CLLocationManagerMock!
    var regionManager: RegionManagerUT!

    override func setUp() {
        super.setUp()
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
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let context = ImmediateContext()
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways, context: context)
        future.onSuccess(context) {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure(context) {error in
            expectation.fulfill()
        }
        self.regionManager.monitoringDidFailForRegion(self.testCLRegion, withError: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartMonitoringAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.regionManager.startMonitoringForRegion(self.testRegion, authorization: .AuthorizedAlways)
        future.onSuccess {state in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        self.regionManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
//    func testDidEnterRegion() {
//        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let region = RegionMock(identifier:"region")
//        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:region)
//        future.onSuccess {state in
//            if state == .Start {
//                mock.regionImpl.didEnterRegion(region)
//            } else {
//                XCTAssert(state == .Inside, "region state invalid")
//                expectation.fulfill()
//            }
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testDidExitRegion() {        
//        let mock = RegionManagerMock(responseAuthorization:.AuthorizedAlways)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let region = RegionMock(identifier:"region")
//        let future = mock.regionImpl.startMonitoringForRegion(mock, authorization:.AuthorizedAlways, region:region)
//        future.onSuccess {state in
//            if state == .Start {
//                mock.regionImpl.didExitRegion(region)
//            } else {
//                XCTAssert(state == .Outside, "region state invalid")
//                expectation.fulfill()
//            }
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
}
