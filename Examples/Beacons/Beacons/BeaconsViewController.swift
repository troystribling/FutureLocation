//
//  BeaconsViewController.swift
//  Beacons
//
//  Created by Troy Stribling on 4/6/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreLocation
import FutureLocation

class BeaconsViewController: UITableViewController {
    
    var beaconRegion    : BeaconRegion?
    
    struct MainStoryBoard {
        static let beaconCell   = "BeaconCell"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"updateBeacons", name:AppNotification.didUpdateBeacon, object:self.beaconRegion)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender: AnyObject!) {
    }
    
    func updateBeacons() {
        self.tableView.reloadData()
    }
    
    func sortedBeacons(beaconRegion:BeaconRegion) -> [Beacon] {
        return  beaconRegion.beacons.sort {(b1:Beacon, b2:Beacon) -> Bool in
            if b1.major > b2.major {
                return true
            } else if b1.major == b2.major && b1.minor > b2.minor {
                return true
            } else {
                return false
            }
        }
    }
    
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let beaconRegion = self.beaconRegion {
            return beaconRegion.beacons.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryBoard.beaconCell, forIndexPath: indexPath) as! BeaconCell
        if let beaconRegion = self.beaconRegion {
            let beacon = self.sortedBeacons(beaconRegion)[indexPath.row]
            cell.proximityUUIDLabel.text = beacon.proximityUUID.UUIDString
            cell.majorLabel.text = "\(beacon.major)"
            cell.minorLabel.text = "\(beacon.minor)"
            cell.proximityLabel.text = beacon.proximity.stringValue
            cell.rssiLabel.text = "\(beacon.rssi)"
            let accuracy = NSString(format:"%.4f", beacon.accuracy)
            cell.accuracyLabel.text = "\(accuracy)m"
        }
        return cell
    }
    
}
