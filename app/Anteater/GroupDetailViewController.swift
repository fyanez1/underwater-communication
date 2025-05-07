//
//  GroupDetailViewController.swift
//  Anteater
//
//  Created by Rachel Lu on 4/15/25.
//  Copyright © 2025 MIT. All rights reserved.
//

import UIKit

class GroupDetailViewController: UIViewController, UITableViewDataSource {

    var group: [Reading]
    
    // Initialize with the group of readings
    init(group: [Reading]) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Group Readings"
        
        // Set up a table view to display the group
        let tableView = UITableView(frame: self.view.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "sensorCell")
        self.view.addSubview(tableView)
    }
    
    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reading = group[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "sensorCell", for: indexPath)
        
        // Format the reading data
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        cell.textLabel?.text = "\(reading)"
        cell.detailTextLabel?.text = formatter.string(from: reading.date)
        
        switch reading.type {
        case .Temperature:
            cell.imageView?.image = #imageLiteral(resourceName: "thermo")
        case .Conductivity:
            cell.imageView?.image = #imageLiteral(resourceName: "conductivity")
        default:
            break
        }
        
        return cell
    }
}
