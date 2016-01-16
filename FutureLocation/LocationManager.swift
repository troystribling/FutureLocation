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
    static let context = QueueContext(queue: queue)

    static func serialSet<T, U>(inout dictionary: [T: U], key: T, value: U) {
        self.queue.sync { dictionary[key] = value }
    }

    static func serialGet<T, U>(dictionary: [T: U], key: T) -> U? {
        return self.queue.sync { return dictionary[key] }
    }
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

    var delegate: CLLocationManagerDelegate? { get set }

    static func authorizationStatus() -> CLAuthorizationStatus
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()

    var location: CLLocation? { get }

    var pausesLocationUpdatesAutomatically: Bool { get set }
    var allowsBackgroundLocationUpdates: Bool { get set}
    var activityType: CLActivityType { get set }
    var distanceFilter : CLLocationDistance { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }

    static func locationServicesEnabled() -> Bool
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()

    static func deferredLocationUpdatesAvailable() -> Bool
    func allowDeferredLocationUpdatesUntilTraveled(distance: CLLocationDistance, timeout: NSTimeInterval)

    static func significantLocationChangeMonitoringAvailable() -> Bool
    func startMonitoringSignificantLocationChanges()
    func stopMonitoringSignificantLocationChanges()

    var monitoredRegions: Set<CLRegion> { get }
    var maximumRegionMonitoringDistance: CLLocationDistance { get }
    func startMonitoringForRegion(region: CLRegion)
    func stopMonitoringForRegion(region: CLRegion)

    static func isRangingAvailable() -> Bool
    var rangedRegions: Set<CLRegion> { get }
    func startRangingBeaconsInRegion(region: CLBeaconRegion)
    func stopRangingBeaconsInRegion(region: CLBeaconRegion)
    func requestStateForRegion(region: CLRegion)
}

extension CLLocationManager : CLLocationManagerInjectable {}

// MARK: - LocationManager -
public class LocationManager : NSObject, CLLocationManagerDelegate {

    // MARK: Properties
    private var _locationUpdatePromise: StreamPromise<[CLLocation]>?
    private var _deferredLocationUpdatePromise: Promise<Void>?
    private var _requestLocationPromise: Promise<[CLLocation]>?
    private var _authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>?

    private var _updating = false

    internal var clLocationManager: CLLocationManagerInjectable

    public var isUpdating: Bool {
        return self.updating
    }

    public var location: CLLocation? {
        return self.clLocationManager.location
    }

    private var locationUpdatePromise: StreamPromise<[CLLocation]>? {
        get {
            return LocationManagerIO.queue.sync { return self._locationUpdatePromise }
        }
        set {
            LocationManagerIO.queue.sync { self._locationUpdatePromise = newValue }
        }
    }

    private var deferredLocationUpdatePromise: Promise<Void>? {
        get {
            return LocationManagerIO.queue.sync { return self._deferredLocationUpdatePromise}
        }
        set {
            LocationManagerIO.queue.sync { self._deferredLocationUpdatePromise = newValue }
        }
    }

    private var requestLocationPromise: Promise<[CLLocation]>? {
        get {
            return LocationManagerIO.queue.sync { return self._requestLocationPromise }
        }
        set {
            LocationManagerIO.queue.sync { self._requestLocationPromise = newValue }
        }
    }

    private var authorizationStatusChangedPromise: Promise<CLAuthorizationStatus>? {
        get {
            return LocationManagerIO.queue.sync { return self._authorizationStatusChangedPromise }
        }
        set {
            LocationManagerIO.queue.sync { self._authorizationStatusChangedPromise = newValue }
        }
    }

    private var updating: Bool {
        get {
            return LocationManagerIO.queue.sync { return self._updating }
        }
        set {
            LocationManagerIO.queue.sync { self._updating = newValue }
        }
    }

    // MARK: Configure
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
            return self.clLocationManager.allowsBackgroundLocationUpdates
        }
        set {
            self.clLocationManager.allowsBackgroundLocationUpdates = newValue
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

    // MARK: Authorization
    class func authorizationStatus() -> CLAuthorizationStatus {
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

    public override init() {
        self.clLocationManager = CLLocationManager()
        super.init()
        self.clLocationManager.delegate = self
    }

    public init(locationManager: CLLocationManagerInjectable) {
        self.clLocationManager = locationManager
        super.init()
        self.clLocationManager.delegate = self
    }

    // MARK: Reverse Geocode
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

    public func reverseGeocodeLocation()  -> Future<[CLPlacemark]>  {
        if let location = self.location {
            return LocationManager.reverseGeocodeLocation(location)
        } else {
            let promise = Promise<[CLPlacemark]>()
            promise.failure(FLError.locationUpdateFailed)
            return promise.future
        }
    }

    // MARK: Control Location Updates
    public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public func startUpdatingLocation(capacity: Int? = nil, authorization: CLAuthorizationStatus = .AuthorizedWhenInUse) -> FutureStream<[CLLocation]> {
            self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
            let authoriztaionFuture = self.authorize(authorization)
            authoriztaionFuture.onSuccess {status in
                self.updating = true
                self.clLocationManager.startUpdatingLocation()
            }
            authoriztaionFuture.onFailure {error in
                self.updating = false
                self.locationUpdatePromise!.failure(error)
            }
            return self.locationUpdatePromise!.future
    }

    public func stopUpdatingLocation() {
        self.updating = false
        self.locationUpdatePromise = nil
        self.clLocationManager.stopUpdatingLocation()
    }

    public func requestLocation() -> Future<[CLLocation]> {
        self.requestLocationPromise = Promise<[CLLocation]>()
        self.clLocationManager.requestLocation()
        return self.requestLocationPromise!.future
    }

    // MARK: Control Significant Change in Location Updates
    public class func significantLocationChangeMonitoringAvailable() -> Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }

    public func startMonitoringSignificantLocationChanges(capacity: Int? = nil, authorization: CLAuthorizationStatus = .AuthorizedAlways) -> FutureStream<[CLLocation]> {
        self.locationUpdatePromise = StreamPromise<[CLLocation]>(capacity:capacity)
        let authoriztaionFuture = self.authorize(authorization)
        authoriztaionFuture.onSuccess {status in
            self.updating = true
            self.clLocationManager.startMonitoringSignificantLocationChanges()
        }
        authoriztaionFuture.onFailure {error in
            self.updating = false
            self.locationUpdatePromise!.failure(error)
        }
        return self.locationUpdatePromise!.future
    }
    
    public func stopMonitoringSignificantLocationChanges() {
        self.updating = false
        self.locationUpdatePromise  = nil
        self.clLocationManager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: Deferred Location Updates
    public class func deferredLocationUpdatesAvailable() -> Bool {
        return CLLocationManager.deferredLocationUpdatesAvailable()
    }

    public func allowDeferredLocationUpdatesUntilTraveled(distance: CLLocationDistance, timeout: NSTimeInterval) -> Future<Void> {
        self.deferredLocationUpdatePromise = Promise<Void>()
        self.clLocationManager.allowDeferredLocationUpdatesUntilTraveled(distance, timeout: timeout)
        return self.deferredLocationUpdatePromise!.future
    }

    // MARK: CLLocationManagerDelegate
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        Logger.debug()
        if let requestLocationPromise = self.requestLocationPromise {
            requestLocationPromise.success(locations)
        }
        self.requestLocationPromise = nil
        self.locationUpdatePromise?.success(locations)
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: NSError) {
        Logger.debug("error \(error.localizedDescription)")
        if let requestLocationPromise = self.requestLocationPromise {
            requestLocationPromise.failure(error)
        }
        self.requestLocationPromise = nil
        self.locationUpdatePromise?.failure(error)
    }

    public func locationManager(_: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        if let error = error {
            self.deferredLocationUpdatePromise?.failure(error)
        } else {
            self.deferredLocationUpdatePromise?.success()
        }
        self.deferredLocationUpdatePromise = nil
    }
        
    public func locationManager(_: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        Logger.debug("status: \(status)")
        self.authorizationStatusChangedPromise?.success(status)
        self.authorizationStatusChangedPromise = nil
    }
    
}
