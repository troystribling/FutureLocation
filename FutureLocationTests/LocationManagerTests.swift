//
//  LocationManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/28/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreLocation
import FutureLocation

struct TestFailure {
    static let error = NSError(domain:"Future Location Tests", code:100, userInfo:[NSLocalizedDescriptionKey:"Testing"])
}

class LocationManagerTests: XCTestCase {

    let testLocations = [CLLocation(latitude: 37.760412, longitude: -122.414602), CLLocation(latitude: 37.745480, longitude: -122.420092)]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAuthorizedAlwaysWhenAuthorizedAlways() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = locationManager.authorize(.AuthorizedAlways)
        future.onSuccess {
            XCTAssertFalse(mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedAlwaysSuccess() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = locationManager.authorize(.AuthorizedAlways)
        future.onSuccess {
            XCTAssert(mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        locationManager.didChangeAuthorizationStatus(.AuthorizedAlways)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedAlwaysFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = locationManager.authorize(.AuthorizedAlways)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization not called")
            expectation.fulfill()
        }
        locationManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedWhenInUseWhenAuthorizedWhenInUse() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedWhenInUse
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = locationManager.authorize(.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssertFalse(mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAuthorizedWhenInUseSuccess() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = locationManager.authorize(.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssert(mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        locationManager.didChangeAuthorizationStatus(.AuthorizedWhenInUse)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAuthorizedWhenInUseFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = locationManager.authorize(.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization not called")
            XCTAssert(error.code == LocationError.AuthorisedWhenInUseFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        locationManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    

    func testUpdateLocationSuccess() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = locationManager.startUpdatingLocation(authorization: .AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(locations.count == 2, "locations count invalid")
            XCTAssert(mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        locationManager.didUpdateLocations(self.testLocations)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUpdateLocationFailure() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = locationManager.startUpdatingLocation(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            expectation.fulfill()
        }
        locationManager.didFailWithError(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testUpdateLocationAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let mock = CLLocationManagerMock()
        let locationManager = LocationManagerUT(clLocationManager: mock)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = locationManager.startUpdatingLocation(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssertFalse(mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        locationManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
 
//    func testUpdateSignificantLocationChangesSuccess() {
//        let mock = LocationManagerMock(responseAuthorization:.AuthorizedAlways)
//        let expectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = mock.impl.startMonitoringSignificantLocationChanges(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
//        future.onSuccess {locations in
//            XCTAssert(locations.count == 2, "locations count invalid")
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testUpdateSignificantLocationChangesFailure() {
//        let mock = LocationManagerMock(responseAuthorization:.AuthorizedAlways, error:TestFailure.error)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startMonitoringSignificantLocationChanges(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
//        future.onSuccess {locations in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//    
//    func testUpdateSignificantLocationChangesAuthorizationFailure() {
//        let mock = LocationManagerMock(responseAuthorization:.Denied, error:TestFailure.error)
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startMonitoringSignificantLocationChanges(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
//        future.onSuccess {locations in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
//            expectation.fulfill()
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
}
