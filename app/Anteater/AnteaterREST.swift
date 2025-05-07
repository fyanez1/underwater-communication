//
//  AnteaterREST.swift
//  Anteater
//
//  Created by Justin Anderson on 1/25/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import Foundation

class AnteaterREST {

    // MARK: - Class variables

    private static let timeout = 5.0

    private static let anthillURLString = "http://carteldb.csail.mit.edu/rest/get_anthills"
    private static let leaderboardURLString = "http://carteldb.csail.mit.edu/rest/leaderboard"
    private static let registerUserURLString = "http://carteldb.csail.mit.edu/rest/register_user"
    private static let postSensorReadingsURLString = "http://carteldb.csail.mit.edu/rest/post_data"
    
    // MARK: - General calls
    
    private class func fetchURLAndParseJSONObject(url: URL, completionHandler: @escaping ([String: Any]?, URLResponse?) -> Void = {_,_ in }) {
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            // Unwrapping Error? into Error means this is skipped when error == nil
            if let error = error {
                print(error)
                return
            }
            guard let data = data else { return }
            let jsonAny = try? JSONSerialization.jsonObject(with: data)
            let jsonObject = jsonAny as? [String: Any]
            completionHandler(jsonObject, response)
        }
        task.resume()
    }
    
    private class func postJSONObjectAndParseJSONObject(url: URL, postObject: [String: Any]?, completionHandler: @escaping ([String: Any]?, URLResponse?) -> Void = {_,_ in }) {
        // Unwrap optional, serialize Dictionary into Data?
        guard let postObject = postObject,
            let postData = try? JSONSerialization.data(withJSONObject: postObject) else {
                print("Failed to serialize postObject as JSON.")
                return
        }
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = postData
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else { return }
            let jsonAny = try? JSONSerialization.jsonObject(with: data)
            let jsonObject = jsonAny as? [String: Any]
            completionHandler(jsonObject, response)
        }
        task.resume()
    }
    
    // MARK: - Anteater REST calls
    
    class func fetchListOfAnthills(completionHandler: @escaping ([[String: Any]]?) -> Void) {
        guard let url = URL(string: anthillURLString) else {
            return
        }
        fetchURLAndParseJSONObject(url: url) { (jsonObject, response) in
            let anthills = jsonObject?["anthills"] as? [[String: Any]] ?? nil
            completionHandler(anthills)
        }
    }
    
    class func fetchLeaderboard(completionHandler: @escaping ([[String: Any]]?) -> Void) {
        guard let url = URL(string: leaderboardURLString) else {
            return
        }
        fetchURLAndParseJSONObject(url: url) { (jsonObject, response) in
            let users = jsonObject?["users"] as? [[String: Any]] ?? nil
            completionHandler(users)
        }
    }
    
    class func registerUser(username: String, deviceId: String, completionHandler: @escaping ([String: Any]?, Bool) -> Void) {
        guard let url = URL(string: registerUserURLString) else { return }
        let postObject = [
            "user_info": [
                "name": username,
                "deviceid": deviceId
            ]
        ]
        postJSONObjectAndParseJSONObject(url: url, postObject: postObject) { (responseObject, response) in
            var succeeded = false
            if let httpResponse = response as? HTTPURLResponse {
                succeeded = [200, 201, 204].contains(httpResponse.statusCode)
            }
            completionHandler(responseObject, succeeded)
        }
    }
    
    class func uploadSensorReadings(readings: [Any]) {
        guard let url = URL(string: postSensorReadingsURLString) else { return }
        let postObject = [
            "readings": readings
        ]
        // No completion handler. Fire and forget.
        postJSONObjectAndParseJSONObject(url: url, postObject: postObject)
    }
    
}
