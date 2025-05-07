//
//  AnthillAnnotation.swift
//  Anteater
//
//  Created by Justin Anderson on 1/25/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import UIKit
import MapKit

class AnthillAnnotation: NSObject, MKAnnotation {
    let title: String?
    let coordinate: CLLocationCoordinate2D
    let lastHeard: TimeInterval?
    var subtitle: String? {
        guard let lastHeard = lastHeard else {
            return "No connections (5 points)"
        }
        let date = Date(timeIntervalSince1970: lastHeard)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let dateString = formatter.string(from: date)
        return "Last heard: \(dateString). (\(pointsForVisiting()) points)"
    }

    init(title: String, lastHeard: TimeInterval?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
        self.lastHeard = lastHeard

        super.init()
    }

    func color() -> UIColor {
        guard let lastHeard = lastHeard else {
            return UIColor.red
        }
        if (lastHeard > 30 * 60) { // 30 minutes
            return UIColor.yellow
        } else {
            return UIColor.green
        }
    }
    
    private func pointsForVisiting() -> Int {
        guard let lastHeard = lastHeard else {
            return 5
        }
        switch lastHeard {
        case let x where x > 360 * 10:
            return 2
        case let x where x > 360 * 5:
            return 1
        default:
            return 0
        }
    }
}
