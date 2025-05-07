//
//  SensorModel.swift
//  Anteater
//
//  Created by Justin Anderson on 8/1/16.
//  Copyright © 2016 MIT. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

protocol SensorModelDelegate {
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?)
    func sensorModel(_ model: SensorModel, didReceiveReadings readings: [Reading], forHill hill: Hill?)
}

extension Notification.Name {
    public static let SensorModelActiveHillChanged = Notification.Name(rawValue: "SensorModelActiveHillChangedNotification")
    public static let SensorModelReadingsChanged = Notification.Name(rawValue: "SensorModelHillReadingsChangedNotification")
}

enum ReadingType: Int {
    case Unknown = -1
    case Temperature = 1
    case Conductivity = 2
    case Error = 0
}

struct Reading {
    let type: ReadingType
    let value: Double
    let date: Date = Date()
    let sensorId: String?
    
    func toJson() -> [String: Any] {
        return [
            "value": self.value,
            "type": self.type.rawValue,
            "timestamp": self.date.timeIntervalSince1970,
            "userid": UIDevice.current.identifierForVendor?.uuidString ?? "NONE",
            "sensorid": sensorId ?? "NONE"
        ]
    }
}

extension Reading: CustomStringConvertible {
    var description: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        guard let numberString = formatter.string(from: NSNumber(value: self.value)) else {
            print("Double \"\(value)\" couldn't be formatted by NumberFormatter")
            return "NaN"
        }
        switch type {
        case .Temperature:
            return "\(numberString)°C"
        case .Conductivity:
            return "\(numberString)mS/cm"
        default:
            return "\(type)"
        }
    }
}

struct Hill {
    var readings: [Reading]
    var name: String
    
    init(name: String) {
        readings = []
        self.name = name
    }
}

extension Hill: CustomStringConvertible, Hashable, Equatable {
    var description: String {
        return name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: Hill, rhs: Hill) -> Bool {
    return lhs.name == rhs.name
}

class SensorModel: BLEDelegate {
    
    static let kBLE_SCAN_TIMEOUT = 10000.0
    
    static let shared = SensorModel()

    var delegate: SensorModelDelegate?
    var sensorReadings: [ReadingType: [Reading]] = [.Temperature: [], .Conductivity: []]
    var activeHill: Hill?
    
    var ble: BLE
    var hillPeripheral: CBPeripheral?
    
    init() {
        ble = BLE()
        ble.delegate = self
    }
    
    func ble(didUpdateState state: BLEState){
        if state == .poweredOn {
            _ = ble.startScanning(timeout: SensorModel.kBLE_SCAN_TIMEOUT)
        }
    }
    
    func ble(didDiscoverPeripheral peripheral: CBPeripheral){
        _ = ble.connectToPeripheral(peripheral)
    }
    
    func ble(didConnectToPeripheral peripheral: CBPeripheral){
        let hill = Hill(name: peripheral.name ?? "NAME")
        activeHill = hill
        hillPeripheral = peripheral
        delegate?.sensorModel(self, didChangeActiveHill: hill)
    }
    
    func ble(didDisconnectFromPeripheral peripheral: CBPeripheral){
        if peripheral == hillPeripheral {
            activeHill = nil
            hillPeripheral = nil
            delegate?.sensorModel(self, didChangeActiveHill: nil)
            _ = ble.startScanning(timeout: SensorModel.kBLE_SCAN_TIMEOUT)
        }
    }
    
    func ble(_ peripheral: CBPeripheral, didReceiveData data: Data?) {
        let str = String(data: data!, encoding: String.Encoding.ascii)!
        
        // Split the string using the "|" delimiter
        let components = str.split(separator: "|")
        
        // Ensure we have at least two components before accessing
        if components.count >= 2,
           let conductivity = Double(components[0]),
           let temperature = Double(components[1]) {
            
            print("Conductivity: \(conductivity)")
            print("Temperature: \(temperature)")
            
            // Create Reading objects for each sensor type
            let readingObj: Reading = Reading(type: .Conductivity, value: conductivity, sensorId: peripheral.name)
            activeHill?.readings.append(readingObj)
            
            let readingObj2: Reading = Reading(type: .Temperature, value: temperature, sensorId: peripheral.name)
            activeHill?.readings.append(readingObj2)

            // Notify the delegate with the readings
            delegate?.sensorModel(self, didReceiveReadings: [readingObj, readingObj2], forHill: activeHill)
        } else {
            print("Error: Could not parse conductivity and temperature.")
        }
    }
}
