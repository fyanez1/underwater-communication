import UIKit

class HillsTableViewController: UITableViewController, SensorModelDelegate {

    var hills: [Hill] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SensorModel.shared.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - SensorModel delegation
    
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?) {
        if let hill = hill {
            hills = [hill]
        }
        self.tableView.reloadData()
    }
    
    func sensorModel(_ model: SensorModel, didReceiveReadings readings: [Reading], forHill hill: Hill?) {
        if let hill = hill {
            hills = [hill]
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Helper Methods
    
    func groupReadings(_ readings: [Reading]) -> [[Reading]] {
        var groupedReadings: [[Reading]] = []
        var group: [Reading] = []
        
        for reading in readings {
            group.append(reading)
            if group.count == 2 {
                groupedReadings.append(group)
                group = []  // Reset the group for the next set of 2 readings
            }
        }
        
        // Add any remaining readings that didn't complete a group of 2
        if !group.isEmpty {
            groupedReadings.append(group)
        }
        
        return groupedReadings
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let hill = SensorModel.shared.activeHill {
            let groupedReadings = groupReadings(hill.readings)
            return groupedReadings.count + 1 // Each group should be its own section + 1 for anthill cell
        } else {
            return 1  // If no active hill, return 1 sections
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1  // Each section corresponds to one group of readings (1 row per group)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let hill = SensorModel.shared.activeHill else {
            return tableView.dequeueReusableCell(withIdentifier: "noConnCell", for: indexPath)
        }

        let groupedReadings = groupReadings(hill.readings)
        
        // Check if it's the first row (Anteater logo cell)
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "plotCell", for: indexPath)
            cell.imageView?.image = #imageLiteral(resourceName: "anteater-logo")
            cell.textLabel?.text = "\(hill.name) - \(hill.readings.count/2) readings"
            
            return cell
        }
        
        // For other cells, show the readings
        let group = groupedReadings[indexPath.section-1]
        let cell = tableView.dequeueReusableCell(withIdentifier: "sensorCell", for: indexPath)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        if let firstReading = group.first {
            cell.textLabel?.text = formatter.string(from: firstReading.date)
        }
        
        cell.imageView?.image = #imageLiteral(resourceName: "sensor")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if var hill = SensorModel.shared.activeHill {
                hill.readings = []
                SensorModel.shared.activeHill = hill  // Update the shared model
                tableView.reloadData()
            }
        } else {
            // User tapped one of the sensor reading group cells
            if let hill = SensorModel.shared.activeHill {
                let groupedReadings = groupReadings(hill.readings)
                let group = groupedReadings[indexPath.section - 1]
                
                let vc = GroupDetailViewController(group: group)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
