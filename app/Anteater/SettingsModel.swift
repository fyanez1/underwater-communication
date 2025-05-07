//
//  SettingsModel.swift
//  Anteater
//
//  Created by Justin Anderson on 1/30/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import Foundation

class SettingsModel {
    
    enum DefaultsKey: String {
        case Username = "AnteaterUsernameKey"
        case LastConnectedTimes = "AnteaterLastConnectedTimesKey"
    }
    
    static var username: String? { // name to post new readings under
        get {
            print("Got \(UserDefaults.standard.string(forKey: DefaultsKey.Username.rawValue))")
            return UserDefaults.standard.string(forKey: DefaultsKey.Username.rawValue)
        }
        set(newUsername) {
            print("Setting username to \(newUsername)")
            UserDefaults.standard.set(newUsername, forKey: DefaultsKey.Username.rawValue)
        }
    }
    static var lastConnectedTimes: [String: Date]? { // Dictionary of [sensor uuid: date last connected]
        get {
            return UserDefaults.standard.dictionary(forKey: DefaultsKey.LastConnectedTimes.rawValue) as? [String: Date]
        }
        set(newTimes) {
            UserDefaults.standard.set(newTimes, forKey: DefaultsKey.LastConnectedTimes.rawValue)
        }
    }
}
