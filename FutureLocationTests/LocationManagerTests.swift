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
    var mock: CLLocationManagerMock!
    var locationManager: LocationManagerUT!

    override func setUp() {
        super.setUp()
        self.mock = CLLocationManagerMock()
        self.locationManager = LocationManagerUT(clLocationManager: mock)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAuthorizedAlwaysWhenAuthorizedAlways() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.AuthorizedAlways)
        future.onSuccess {
            XCTAssertFalse(self.mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization called")
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
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.AuthorizedAlways)
        future.onSuccess {
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didChangeAuthorizationStatus(.AuthorizedAlways)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedAlwaysFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.locationManager.authorize(.AuthorizedAlways)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.requestAlwaysAuthorizationCalled, "requestAlwaysAuthorization not called")
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedWhenInUseWhenAuthorizedWhenInUse() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedWhenInUse
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssertFalse(self.mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization called")
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
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.locationManager.authorize(.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didChangeAuthorizationStatus(.AuthorizedWhenInUse)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAuthorizedWhenInUseFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.locationManager.authorize(.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.requestWhenInUseAuthorizationCalled, "requestWhenInUseAuthorization not called")
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
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.locationManager.startUpdatingLocation(authorization: .AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(locations.count == 2, "locations count invalid")
            XCTAssert(self.mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didUpdateLocations(self.testLocations)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUpdateLocationFailure() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.locationManager.startUpdatingLocation(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.startUpdatingLocationCalled, "startUpdatingLocation not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            expectation.fulfill()
        }
        self.locationManager.didFailWithError(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testUpdateLocationAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.locationManager.startUpdatingLocation(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssertFalse(self.mock.startUpdatingLocationCalled, "startUpdatingLocation called")
            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
 
    func testUpdateSignificantLocationChangesSuccess() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(locations.count == 2, "locations count invalid")
            XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled, "startMonitoringSignificantLocationChanges called")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        self.locationManager.didUpdateLocations(self.testLocations)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUpdateSignificantLocationChangesFailure() {
        CLLocationManagerMock._authorizationStatus = .AuthorizedAlways
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(self.mock.startMonitoringSignificantLocationChangesCalled, "startUpdatingLocation called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            expectation.fulfill()
        }
        self.locationManager.didFailWithError(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUpdateSignificantLocationChangesAuthorizationFailure() {
        CLLocationManagerMock._authorizationStatus = .NotDetermined
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.locationManager.startMonitoringSignificantLocationChanges(authorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssertFalse(self.mock.startMonitoringSignificantLocationChangesCalled, "startUpdatingLocation called")
            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        self.locationManager.didChangeAuthorizationStatus(.Denied)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
