//
//  LeaderboardTableViewController.swift
//  Anteater
//
//  Created by Justin Anderson on 1/25/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import UIKit

class LeaderboardTableViewController: UITableViewController {

    var leaderboard: [Any]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        AnteaterREST.fetchLeaderboard { [weak self] (leaderboard) in
            DispatchQueue.main.async { [weak self] in
                self?.leaderboard = leaderboard
                self?.tableView.reloadData()
            }
        }        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return leaderboard?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Use our custom tableview cell's contentView with default label text as a section header. 
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell") as! LeaderboardTableViewCell
        
        cell.contentView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 0.9030661387)
        
        return cell.contentView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44.0
        } else {
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EntryCell", for: indexPath) as! LeaderboardTableViewCell

        if let entry = leaderboard?[indexPath.row] as? [String: Any],
            let name = entry["user_id"] as? String,
            let entryUUID = entry["device_id"] as? String,
            let currentUUID = UIDevice.current.identifierForVendor?.uuidString,
            let points = entry["points"] as? Int {
            cell.rankLabel?.text = "\(indexPath.row)."
            cell.nameLabel?.text = (entryUUID == currentUUID) ? "YOU" : name
            cell.pointsLabel?.text = String(points)
            cell.selectionStyle = .none
        }
        
        return cell
    }

}
