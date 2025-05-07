//
//  AnthillMapViewController.swift
//  Anteater
//
//  Created by Justin Anderson on 1/25/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import UIKit
import MapKit

class AnthillMapViewController: UIViewController, MKMapViewDelegate {

    var anthills: [[String:Any]]? = nil
    var annotations: [MKAnnotation]? = nil
    
    @IBOutlet weak var mapView: MKMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        mapView?.userTrackingMode = .followWithHeading

        AnteaterREST.fetchListOfAnthills { [weak self] (anthills) in
            DispatchQueue.main.async { [weak self] in
                self?.anthills = anthills
                self?.addAnnotationsForAnthills()
                self?.zoomToAnnotations()
            }
        }
        
//        MKAnnotation
        
//        mapView?.addAnnotations(annotations: [MKAnnotation])
        // Do any additional setup after loading the view.
    }

    func addAnnotationsForAnthills() {
        if let annotations = annotations {
            mapView?.removeAnnotations(annotations)
        }
        
        annotations = anthills?.compactMap {
            guard var title = $0["id"] as? String,
                let lastHeard = $0["last_heard"] as? Double,
                let lat = $0["lat"] as? Double,
                let lon = $0["lon"] as? Double
            else { return nil }
            if let description = $0["description"] as? String {
                title += " - \(description)"
            }
            return AnthillAnnotation(
                title: title,
                lastHeard: lastHeard,
                coordinate: CLLocationCoordinate2DMake(lat, lon))
        }
        
        if let annotations = annotations {
            mapView?.addAnnotations(annotations)
        }
    }
    
    func zoomToAnnotations() {
        guard let annotations = annotations else { return }
        
        var minLon = 500.0
        var minLat = 500.0
        var maxLon = -500.0
        var maxLat = -500.0
        
        for annotation in annotations {
            minLon = min(minLon, annotation.coordinate.longitude)
            minLat = min(minLat, annotation.coordinate.latitude)
            maxLon = max(maxLon, annotation.coordinate.longitude)
            maxLat = max(maxLat, annotation.coordinate.latitude)
        }
        
        let lon = (minLon + maxLon) / 2
        let lat = (minLat + maxLat) / 2
        var width = maxLon - minLon
        var height = maxLat - minLat
        
        if (height < 0.01) {
            height = 0.01;
        }
        if (width < 0.01) {
            width = 0.01;
        }
        
        let region = MKCoordinateRegion.init(center: CLLocationCoordinate2DMake(lat, lon), span: MKCoordinateSpan.init(latitudeDelta: height, longitudeDelta: width))
        
        self.mapView?.setRegion(region, animated: true)

    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? AnthillAnnotation else {
            return nil
        }
        
        let reuseId = "pinReuseId"
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if (view == nil) {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view?.pinTintColor = annotation.color()
            view?.canShowCallout = true
        }
        return view
    }
    
}
