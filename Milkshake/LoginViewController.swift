//
//  LoginViewController.swift
//  Milkshake
//
//  Created by Dean Liu on 12/11/17.
//  Copyright © 2017 Dean Liu. All rights reserved.
//

import Cocoa
import Locksmith


// MARK: - NSTextFieldDelegate
extension LoginViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            self.loginAction(self)
            return true
        }
        return false
    }
}

class LoginViewController: NSViewController {

    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var errorTextField: NSTextField!
    @IBOutlet weak var rememberButton: NSButton!
    @IBOutlet weak var loginButton: MyButton!
    
    var delegate: LoginProtocol?
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "Milkshake") {
            let username = dictionary["username"] as! String
            let password = dictionary["password"] as! String
            usernameField.stringValue = username
            passwordField.stringValue = password
//            self.loginAction(self) // auto login
            
        }
        self.usernameField.delegate = self
        self.passwordField.delegate = self
        self.usernameField.nextKeyView = self.passwordField
        self.passwordField.nextKeyView = self.rememberButton
        self.rememberButton.nextKeyView = self.loginButton
        self.loginButton.nextKeyView = self.usernameField
    }
    
    func callbackLogin(results: [String: AnyObject]) {
        if let errorCode = results["errorCode"] as? Int {
            if errorCode >= 0 {
                let errorMessage = results["message"] as! String
                errorTextField.stringValue = errorMessage
            }
        } else {
            self.delegate?.handleSuccessLogin(results: results)
        }
    }
    
    func callbackPartnerAuth(results: [String: AnyObject]) {
        let token = results["result"]!["partnerAuthToken"] as! String
        let partnerId = results["result"]!["partnerId"] as! String
        let syncTimeEnc = results["result"]!["syncTime"] as! String
        
        
        let syncTime = PandoraDecryptTime(syncTimeEnc,"R=U!LH$O2B#")
        
        self.appDelegate.api.partnerAuthUserLogin(username: self.usernameField.stringValue, password: self.passwordField.stringValue, partnerAuthToken: token, partnerId: partnerId, syncTime: syncTime, callbackHandler: callbackPartnerAuthUserLogin);
    }
    
    func callbackPartnerAuthUserLogin(results: [String: AnyObject]) {
        if (results["stat"] as? String) != "ok"{
            if (results["code"] as? Int ?? 0) >= 0 {
                errorTextField.stringValue = "Invalid username or credentials"
            }
        } else {
            let result = results["result"] as! Dictionary<String, AnyObject>
            self.delegate?.handleSuccessLogin(results: result)
        }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        let username = usernameField.stringValue
        let password = passwordField.stringValue

        let userData = ["username": username, "password": password]
        if rememberButton.state == NSControl.StateValue.on {
            try? Locksmith.updateData(data: userData, forUserAccount: "Milkshake")
        }
        
        self.appDelegate.api.partnerAuthPartnerLogin(callbackHandler: callbackPartnerAuth);
        
//        self.appDelegate.api.auth(username: self.usernameField.stringValue, pass: self.passwordField.stringValue, callbackHandler: callbackLogin);
    }
}
