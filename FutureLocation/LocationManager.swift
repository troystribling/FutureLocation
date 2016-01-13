//
//  LocationManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/1/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreLocation

// MARK: - Property Update Serialization -
struct LocationManagerIO {
    static let queue = Queue("us.gnos.location-manager")
}

// MARK: - Errors -
public enum LocationError : Int {
    case NotAvailable               = 0
    case UpdateFailed               = 1
    case AuthorizationAlwaysFailed  = 2
    case AuthorisedWhenInUseFailed  = 3
}

public struct FLError {
    public static let domain = "FutureLocation"
    public static let locationUpdateFailed = NSError(domain:domain, code:LocationError.UpdateFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location not available"])
    public static let locationNotAvailable = NSError(domain:domain, code:LocationError.NotAvailable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Location update failed"])
    public static let authoizationAlwaysFailed = NSError(domain:domain, code:LocationError.AuthorizationAlwaysFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization failed"])
    public static let authoizationWhenInUseFailed = NSError(domain:domain, code:LocationError.AuthorisedWhenInUseFailed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Authorization when in use failed"])
}

// MARK: - CLLocationManagerInjectable -
public protocol CLLocationManagerInjectable {
    static func authorizationStatus() -> CLAuthorizationStatus
    static func locationServicesEnabled() -> Bool
    static func significantLocationChangeMonitoringAvailable() -> Bool
    static func deferredLocationUpdatesAvailable() -> Bool
    var delegate: CLLocationManagerDelegate? { get set }
    var location: CLLocation? { get }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var allowsBackgroundLocationUpdates: Bool { get set}
    var activityType: CLActivityType { get set }
    var distanceFilter : CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()
}

extension CLLocationManager : CLLocationManagerInjectable {}

// MARK: - LocationManagerAuthorizable -
internal protocol LocationManagerAuthorizable: class {
    var clLocationManager: CLLocationManagerInjectable { get set }
    var authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>? { get set }

    static func authorizationStatus() -> CLAuthorizationStatus
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
}

internal extension LocationManagerAuthorizable {

    static func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    func requestWhenInUseAuthorization()  {
        self.clLocationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }

    func authorize(authorization: CLAuthorizationStatus) -> Future<Void> {
        let currentAuthorization = LocationManager.authorizationStatus()
        let promise = Promise<Void>()
        if currentAuthorization != authorization {
            self.authorizationStatusChangedPromise = Promise<CLAuthorizationStatus>()
            switch authorization {
            case .AuthorizedAlways:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .AuthorizedAlways {
                        Logger.debug("location AuthorizedAlways succcess")
                        promise.success()
                    } else {
                        Logger.debug("location AuthorizedAlways failed")
                        promise.failure(FLError.authoizationAlwaysFailed)
                    }
                }
                self.requestAlwaysAuthorization()
                break
            case .AuthorizedWhenInUse:
                self.authorizationStatusChangedPromise?.future.onSuccess {(status) in
                    if status == .AuthorizedWhenInUse {
                        Logger.debug("location AuthorizedWhenInUse succcess")
                        promise.success()
                    } else {
                        Logger.debug("location AuthorizedWhenInUse failed")
                        promise.failure(FLError.authoizationWhenInUseFailed)
                    }
                }
                self.requestWhenInUseAuthorization()
                break
            default:
                Logger.debug("location authorization invalid")
                break
            }
        } else {
            promise.success()
        }
        return promise.future
    }

}

// MARK: - LocationManager -
public class LocationManager : NSObject, CLLocationManagerDelegate, LocationManagerAuthorizable {

    private var locationUpdatePromise: StreamPromise<[CLLocation]>?
    private var _isUpdating = false

    internal var authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>?
    internal var clLocationManager: CLLocationManagerInjectable

    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public class func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }

    public class func deferredLocationUpdatesAvailable() -> Bool {
        return CLLocationManager.deferredLocationUpdatesAvailable()
    }

    public var isUpdating: Bool {
        return self._isUpdating
    }

    public var location: CLLocation? {
        return self.clLocationManager.location
    }

    public var pausesLocationUpdatesAutomatically: Bool {
        get {
            return self.clLocationManager.pausesLocationUpdatesAutomatically
        }
        set {
            self.clLocationManager.pausesLocationUpdatesAutomatically = newValue
        }
    }

    public var allowsBackgroundLocationUpdates: Bool {
        get {
            if #available(iOS 9.0, *) {
                return self.clLocationManager.allowsBackgroundLocationUpdates
            } else {
                return false
            }
        }
        set {
            if #available(iOS 9.0, *) {
                self.clLocationManager.allowsBackgroundLocationUpdates = newValue
            }
        }
    }

    public var activityType: CLActivityType {
        get {
            return self.clLocationManager.activityType
        }
        set {
            self.clLocationManager.activityType = newValue
        }
    }

    public var distanceFilter : CLLocationDistance {
        get {
            return self.clLocationManager.distanceFilter
        }
        set {
            self.clLocationManager.distanceFilter = newValue
        }
    }
    
    public var desiredAccuracy: CLLocationAccuracy {
        get {
            return self.clLocationManager.desiredAccuracy
        }
        set {
            self.clLocationManager.desiredAccuracy = newValue
        }
    }

    public class func reverseGeocodeLocation(location: CLLocation) -> Future<[CLPlacemark]>  {
        let geocoder = CLGeocoder()
        let promise = Promise<[CLPlacemark]>()
        geocoder.reverseGeocodeLocation(location){(placemarks:[CLPlacemark]?, error:NSError?) in
            if let error = error {
                promise.failure(error)
            } else {
                if let placemarks = placemarks {
                    promise.success(placemarks)
                } else {
                    promise.success([CLPlacemark]())
                }
            }
        }
        return promise.future
    }
    
    public override init() {
        super.init()
        self.clLocationManager = CLLocationManager()
        self.clLocationManager.delegate = self
    }

    public init(locationManager: CLLocationManagerInjectable) {
        super.init()
        self.clLocationManager = locationManager
        self.clLocationManager.delegate = self
    }

    public func reverseGeocodeLocation()  -> Future<[CLPlacemark]>  {
        if let location = self.location {
            return LocationManager.reverseGeocodeLocation(location)
        } else {
            let promise = Promise<[CLPlacemark]>()
            promise.failure(FLError.locationUpdateFailed)
            return promise.future
        }
    }

    public func startUpdatingLocation(capacity: Int? = nil, authorization: CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self._isUpdating = true
            self.clLocationManager.startUpdatingLocation()
        }
        authoriztaionFuture.onFailure {error in
            self._isUpdating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }

    public func stopUpdatingLocation() {
        self._isUpdating = false
        self.locationUpdatePromise = nil
        self.clLocationManager.stopUpdatingLocation()
    }
    
    public func startMonitoringSignificantLocationChanges(capacity: Int? = nil, authorization: CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self._isUpdating = true
            self.clLocationManager.startMonitoringSignificantLocationChanges()
        }
        authoriztaionFuture.onFailure {error in
            self._isUpdating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        self._isUpdating = false
        self.locationUpdatePromise  = nil
        self.clLocationManager.stopMonitoringSignificantLocationChanges()
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        Logger.debug()
        self.locationUpdatePromise?.success(locations)
    }

    public func locationManager(_:CLLocationManager, didFailWithError error:NSError) {
        Logger.debug("error \(error.localizedDescription)")
        self.locationUpdatePromise?.failure(error)
    }
    
    public func locationManager(_:CLLocationManager, didFinishDeferredUpdatesWithError error:NSError?) {
    }
        
    public func locationManager(_:CLLocationManager, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
        Logger.debug("status: \(status)")
        self.authorizationStatusChangedPromise?.success(status)
        self.authorizationStatusChangedPromise = nil
    }
    
}
