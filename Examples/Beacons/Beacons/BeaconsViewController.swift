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
    
    var beaconRegion: BeaconRegion?
    
    struct MainStoryBoard {
        static let beaconCell   = "BeaconCell"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(BeaconsViewController.updateBeacons), name: NSNotification.Name(rawValue: AppNotification.didUpdateBeacon), object: self.beaconRegion)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
    }
    
    func updateBeacons() {
        self.tableView.reloadData()
    }
    
    func sortedBeacons(_ beaconRegion: BeaconRegion) -> [Beacon] {
        return  beaconRegion.beacons.sorted {(b1: Beacon, b2: Beacon) -> Bool in
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let beaconRegion = self.beaconRegion {
            return beaconRegion.beacons.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryBoard.beaconCell, for: indexPath) as! BeaconCell
        if let beaconRegion = self.beaconRegion {
            let beacon = self.sortedBeacons(beaconRegion)[indexPath.row]
            cell.proximityUUIDLabel.text = beacon.proximityUUID.uuidString
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
