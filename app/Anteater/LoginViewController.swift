//
//  LoginViewController.swift
//  Anteater
//
//  Created by Justin Anderson on 1/30/17.
//  Copyright © 2017 MIT. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField?
    @IBOutlet weak var getStartedButton: UIButton?
    
    @IBAction func getStarted(sender: UIButton) {
        registerUsername()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getStartedButton?.layer.cornerRadius = 5.0
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        registerUsername()
        return true
    }

    func registerUsername() {
        guard let username = usernameField?.text else {
            return
        }
        if username.count < 3 {
            let alert = UIAlertController(
                title: "Invalid Username",
                message: "Please enter a username that is at least 3 characters.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            return
        }
        AnteaterREST.registerUser(
            username: username,
            deviceId: deviceId,
            completionHandler: { [weak self] (responseObject, succeeded) in
                if succeeded == false {
                    let alert = UIAlertController(
                        title: "Request Failed",
                        message: "Network request failed, please try again.",
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                    return
                } else {
                    SettingsModel.username = username
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        )
    }
    
}
