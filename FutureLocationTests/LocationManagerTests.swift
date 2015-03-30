//
//  LocationManagerTests.swift
//  FutureLocation
//
//  Created by Troy Stribling on 3/28/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreLocation
import FutureLocation

struct TestFailure {
    static let error = NSError(domain:"Future Location Tests", code:100, userInfo:[NSLocalizedDescriptionKey:"Testing"])
}

class LocationManagerTests: XCTestCase {

    
    // LocationManagerMock
    class LocationManagerMock : LocationManagerWrappable {

        var impl = LocationManagerImpl<LocationManagerMock>()
        
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
    // LocationManagerMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAuthorizedAlwaysWhenAuthorizedAlways() {
        let mock = LocationManagerMock()
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.authorize(mock, currentAuthorization:.AuthorizedAlways, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {
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
        let mock = LocationManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.authorize(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedAlwaysFailure() {
        let mock = LocationManagerMock(responseAuthorization:.Denied)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.authorize(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAuthorizedWhenInUseWhenAuthorizedWhenInUse() {
        let mock = LocationManagerMock()
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.authorize(mock, currentAuthorization:.AuthorizedWhenInUse, requestedAuthorization:.AuthorizedWhenInUse)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(error.code == LocationError.AuthorizationAlwaysFailed.rawValue, "Error code invalid")
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAuthorizedWhenInUseSuccess() {
        let mock = LocationManagerMock(responseAuthorization:.AuthorizedWhenInUse)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.authorize(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedWhenInUse)
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testAuthorizedWhenInUseFailure() {
        let mock = LocationManagerMock(responseAuthorization:.Denied)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.authorize(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedWhenInUse)
        future.onSuccess {
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(error.code == LocationError.AuthorisedWhenInUseFailed.rawValue, "Error code invalid")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    

    func testUpdateLocationSuccess() {
        let mock = LocationManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startUpdatingLocation(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(locations.count == 2, "locations count invalid")
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testUpdateLocationFailure() {
        let mock = LocationManagerMock(responseAuthorization:.AuthorizedAlways, error:TestFailure.error)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startUpdatingLocation(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {locations in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testUpdateLocationAuthorizationFailure() {
        let mock = LocationManagerMock(responseAuthorization:.Denied, error:TestFailure.error)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startUpdatingLocation(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {locations in
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
    
    func testStopLocationUpdates() {
        let mock = LocationManagerMock(responseAuthorization:.AuthorizedAlways)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startUpdatingLocation(mock, currentAuthorization:.Denied, requestedAuthorization:.AuthorizedAlways)
        future.onSuccess {locations in
            expectation.fulfill()
            mock.impl.stopUpdatingLocation(mock)
            mock.impl.didUpdateLocations([CLLocationMock(), CLLocationMock()])
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
