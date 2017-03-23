//
//  SettingsTableViewController.swift
//  adera
//
//  Created by Nathan Chapman on 3/22/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var passwordCell: UITableViewCell!
    @IBOutlet weak var usernameCell: UITableViewCell!
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var fontSizeLabel: UILabel!
    
    var userID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userID = FIRAuth.auth()?.currentUser?.uid
        self.tableView.tableFooterView = UIView()
        
        updateDetailsViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // App Settings
        if indexPath.section == 0 {
            // Text Size
            if  indexPath.row == 0 {
                // DO NOTHING HERE. This is a slider so selection means nothing.
            }
        }
        // Edit Profile
        else if indexPath.section == 1 {
            // Email
            if  indexPath.row == 0 {
                let alertController = UIAlertController(title: "Change Email Address", message: nil, preferredStyle: .alert)
                let updateEmailAction = UIAlertAction(title: "Update Email Address",
                                                         style: .destructive) { action in
                                                            let textField = alertController.textFields![0]
                                                            if textField.text?.characters.count ?? 0 > 0 {
                                                                FIRAuth.auth()?.currentUser?.updateEmail(textField.text!) { (error) in
                                                                    // Displays Error or Success Message from FireBase
                                                                    let title: String? = error != nil ? "Reauthentication Required" : "Success"
                                                                    let message: String? = error != nil ? error?.localizedDescription : "Successfully Changed Email"
                                                                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                                                                    if error != nil {
                                                                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                                                                        alertController.addAction(cancelAction)
                                                                        let loginAction = UIAlertAction(title: "Re-Login", style: .destructive, handler: self.signOutAction)
                                                                        alertController.addAction(loginAction)
                                                                    }
                                                                    else {
                                                                        self.updateDetailsViews()
                                                                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                                                        alertController.addAction(defaultAction)
                                                                    }
                                                                    self.present(alertController, animated: true, completion: nil)
                                                                }
                                                            }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                alertController.addTextField()
                alertController.addAction(updateEmailAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            // Password
            else if  indexPath.row == 1 {
                let alertController = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
                let updatePasswordAction = UIAlertAction(title: "Update Password",
                                               style: .destructive) { action in
                                                let textField = alertController.textFields![0]
                                                if textField.text?.characters.count ?? 0 > 0 {
                                                    FIRAuth.auth()?.currentUser?.updatePassword(textField.text!) { (error) in
                                                        // Displays Error or Success Message from FireBase
                                                        let title: String? = error != nil ? "Reauthentication Required" : "Success"
                                                        let message: String? = error != nil ? error?.localizedDescription : "Successfully Changed Password"
                                                        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                                                        if error != nil {
                                                            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                                                            alertController.addAction(cancelAction)
                                                            let loginAction = UIAlertAction(title: "Re-Login", style: .destructive, handler: self.signOutAction)
                                                            alertController.addAction(loginAction)
                                                        }
                                                        else {
                                                            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                                            alertController.addAction(defaultAction)
                                                        }
                                                        self.present(alertController, animated: true, completion: nil)
                                                    }
                                                }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                alertController.addTextField()
                alertController.addAction(updatePasswordAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            // Username
            else if  indexPath.row == 2 {
                let alertController = UIAlertController(title: "Change Username", message: nil, preferredStyle: .alert)
                let updateUsernameAction = UIAlertAction(title: "Update Username",
                                                         style: .destructive) { action in
                                                            let textField = alertController.textFields![0]
                                                            if textField.text?.characters.count ?? 0 > 0 {
                                                                let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                                                                changeRequest?.displayName = textField.text!
                                                                changeRequest?.commitChanges() { (error) in
                                                                    // Displays Error or Success Message from FireBase
                                                                    let title: String? = error != nil ? "Error" : "Success"
                                                                    let message: String? = error != nil ? error?.localizedDescription : "Successfully Changed Username"
                                                                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                                                                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                                                    alertController.addAction(defaultAction)
                                                                    self.updateDetailsViews()
                                                                    self.present(alertController, animated: true, completion: nil)
                                                                }
                                                            }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                alertController.addTextField()
                alertController.addAction(updateUsernameAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.white
        headerView.textLabel?.textColor = self.view.tintColor
        headerView.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
    }

    func signOutAction(_ sender: Any) {
        print("sign out")
        try! FIRAuth.auth()!.signOut()
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func updateDetailsViews() {
        // Get Application Settings Values from FireBase
        AppDelegate.usersRef.child(userID!).child("settings").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let fontSize = value?["fontSize"] as? Int ?? AccountDefaultSettings().fontSize
            self.fontSizeSlider.value = Float(fontSize)
        }) { (error) in
            print(error.localizedDescription)
        }
        
        let email = FIRAuth.auth()?.currentUser?.email
        emailCell.detailTextLabel?.text = email
        
        let displayName = FIRAuth.auth()?.currentUser?.displayName
        usernameCell.detailTextLabel?.text = displayName
        
        passwordCell.detailTextLabel?.text = "******"
    }
    
    @IBAction func fontSliderValueChanged(_ sender: Any) {
        let fontSize = Int(self.fontSizeSlider.value)
        print(fontSize)
        UILabel.appearance().font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        AppDelegate.usersRef.child(userID!).child("settings").child("fontSize").setValue(fontSize)
        fontSizeLabel.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
    }
}
