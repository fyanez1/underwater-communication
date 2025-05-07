//
//  CompassViewController.swift
//  Anteater
//
//  Created by Justin Anderson on 1/24/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import UIKit
import CoreLocation

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
    var radiansToDegrees: Double { return Double(self) * 180 / .pi }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

class CompassViewController: UIViewController, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var anthills: [Any]? = nil
 
    let locationManager = CLLocationManager()
    var lastCoord, userCoord, targetCoord: CLLocationCoordinate2D?
    var curHeading = 0.0, lastHeading = 0.0, lastMagHeading = 0.0
    var scale: CGFloat = 0.0
    
    // MARK: Outlets and Actions
    
    @IBOutlet weak var picker: UIPickerView?
    @IBOutlet weak var compass: UIImageView?
    @IBOutlet weak var needle: UIImageView?
    @IBOutlet weak var headingLabel: UILabel?
    @IBOutlet weak var distanceLabel: UILabel?

    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        picker?.dataSource = self
        picker?.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 0
        locationManager.headingOrientation = .portrait
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    
        self.headingLabel?.text = ""
        self.distanceLabel?.text = ""

        AnteaterREST.fetchListOfAnthills { [weak self] (anthills) in
            DispatchQueue.main.async { [weak self] in
                self?.anthills = anthills
                self?.picker?.reloadAllComponents()
            }
        }
    }

    // MARK: - UIPickerView delegation
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return anthills?.count ?? 0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let anthill = anthills?[row] as! [String: Any]?,
            let title = anthill["id"] as! String? else {
            return ""
        }
        return title
    }
    
    // TODO: implement me
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // your code here
    }
    
    // MARK: - CoreLocation
    
    // TODO: implement me
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // your code here
    }
    
    // TODO: implement me
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // your code here
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print(status)
        print(status.rawValue)
    }
}
