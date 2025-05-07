//
//  SensorDataPlotViewController.swift
//  Anteater
//
//  Created by Justin Anderson on 1/29/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import UIKit
import CorePlot

private let maxAge: TimeInterval = 150

class SensorDataPlotViewController: UIViewController, CPTScatterPlotDataSource {

    enum PlotName: String {
        case Temperature = "Temperature"
        case Conductivity = "Conductivity"
    }
    
    var g: CPTXYGraph?
    var hill: Hill?
    var temperatureReadings: [Reading]?
    var conductivityReadings: [Reading]?
    var earliestDate: Date = Date.distantPast
    var latestDate: Date = Date()
    
    convenience init(hill: Hill?) {
        self.init(nibName: nil, bundle: nil)
        self.hill = hill
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let g = CPTXYGraph(frame: view.frame)
        g.apply(CPTTheme(named: .plainWhiteTheme))
        g.paddingTop = 0
        g.paddingBottom = 65
        g.paddingLeft = 0
        g.paddingRight = 0
        let gview = CPTGraphHostingView(frame: view.frame)
        gview.hostedGraph = g
        view.addSubview(gview)
        
        let p1 = CPTScatterPlot(frame: .zero)
        let style = CPTMutableLineStyle()
        style.miterLimit = 1.0
        style.lineWidth = 3.0
        style.lineColor = CPTColor.blue()
        p1.dataLineStyle = style
        p1.identifier = PlotName.Conductivity.rawValue as (NSCoding & NSCopying & NSObjectProtocol)?
        p1.dataSource = self
        g.add(p1)
        
        let p2 = CPTScatterPlot(frame: .zero)
        let style2 = CPTMutableLineStyle()
        style2.miterLimit = 1.0
        style2.lineWidth = 3.0
        style2.lineColor = CPTColor.red()
        p2.dataLineStyle = style2
        p2.identifier = PlotName.Temperature.rawValue as (NSCoding & NSCopying & NSObjectProtocol)?
        p2.dataSource = self
        g.add(p2)
        
        g.plotAreaFrame?.paddingLeft = 30.0
        g.plotAreaFrame?.paddingBottom = 30.0
        
        self.g = g
        gview.allowPinchScaling = false
        gview.isUserInteractionEnabled = false
        
        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        // Any change while viewing the graph means we're not looking at the same hill anymore, so the graph isn't valid. Stop watching for new readings.
        NotificationCenter.default.addObserver(forName: .SensorModelActiveHillChanged, object: nil, queue: nil) { [weak self] (notification) in
            if let unwrappedSelf = self {
                NotificationCenter.default.removeObserver(unwrappedSelf)
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(notification:)), name: .SensorModelReadingsChanged, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func handleNotification(notification: Notification) {
        guard let hill = notification.object as? Hill else {
            return
        }
        self.hill = hill
        reloadData()
    }
    
    func reloadData() {
        guard let hill = self.hill else {
            return
        }
        let boundedReadings = hill.readings
            .filter { $0.date.timeIntervalSinceNow * -1 <= maxAge }
            .sorted { $0.date > $1.date }
        guard let firstReading = boundedReadings.first,
            let lastReading = boundedReadings.last else {
                print("Failed to find an first and late date among sensor readings.")
                return
        }
        self.earliestDate = firstReading.date
        self.latestDate = lastReading.date
        let minTime = firstReading.date.timeIntervalSinceNow * -1
        let maxTime = lastReading.date.timeIntervalSinceNow * -1
        self.conductivityReadings = boundedReadings.filter { $0.type == .Conductivity }
        self.temperatureReadings = boundedReadings.filter { $0.type == .Temperature }
        self.configAxes(minX: minTime, maxX: maxTime)
        self.g?.reloadData()
    }
    
    func configAxes(minX: TimeInterval, maxX: TimeInterval) {
        
        let ps: CPTXYPlotSpace? = g?.defaultPlotSpace as? CPTXYPlotSpace
        ps?.allowsUserInteraction = true
        var wid = maxX - minX
        if wid > maxAge {
            wid = maxAge
        }
        
        ps?.xRange = CPTPlotRange(location: NSNumber(value: maxX - (wid * 1.1)), length: NSNumber(value: wid + (wid * 0.2)))
        ps?.yRange = CPTPlotRange(location: NSNumber(value: 0), length: NSNumber(value: 120))
        
        let a = g?.axisSet as? CPTXYAxisSet
        a?.xAxis?.majorIntervalLength = NSNumber(value: (maxX - minX) / 10.0)
        a?.yAxis?.majorIntervalLength = NSNumber(value: 10)
        
        let x = a?.xAxis
        x?.labelRotation = .pi / 4.0
        x?.labelingPolicy = .none
        
        var customLabels: [CPTAxisLabel] = []

        for i in 0..<Int(maxAge) where i % 10 == 0 {
            let label = CPTAxisLabel(text: "\(i)s", textStyle: x?.labelTextStyle)
            label.tickLocation = NSNumber(value: i)
            label.offset = 0
            label.rotation = .pi / 4.0
            customLabels.append(label)
        }
        
        x?.axisLabels = Set(customLabels)
    }
        
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        guard let identifier = plot.identifier as? String,
            let plot = PlotName(rawValue: identifier) else {
            return 0
        }
        switch plot {
        case .Conductivity:
            return UInt(conductivityReadings?.count ?? 0)
        case .Temperature:
            return UInt(temperatureReadings?.count ?? 0)
        }
    }

    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        guard let identifier = plot.identifier as? String else {
            return 0
        }
        let readings: [Reading]?
            
        switch identifier {
            case PlotName.Temperature.rawValue:
                readings = temperatureReadings
            case PlotName.Conductivity.rawValue:
                readings = conductivityReadings
            default:
                readings = nil
        }
        
        let i = Int(idx)
        if CPTScatterPlotField.X.rawValue == Int(fieldEnum) {
            guard let date = readings?[i].date else {
                return 0.0
            }
            return date.timeIntervalSince(latestDate)
        } else { // Y-axis
            return readings?[i].value
        }
    }
}
