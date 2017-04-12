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
    @IBOutlet weak var colorSchemeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sortingMethodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    var userID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userID = FIRAuth.auth()?.currentUser?.uid
        self.tableView.tableFooterView = UIView()
        
        userPhotoImageView.image = UIImage(named: "DefaultAvatar.png")
        userPhotoImageView.layer.cornerRadius = userPhotoImageView.frame.width / 2
        userPhotoImageView.layer.masksToBounds = true
        self.userPhotoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapUserPhoto)))
        self.userPhotoImageView.isUserInteractionEnabled = true
        self.colorSchemeSegmentedControl.apportionsSegmentWidthsByContent = true
        self.sortingMethodSegmentedControl.apportionsSegmentWidthsByContent = true
        
        updateDetailsViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = true
        self.view.backgroundColor = UIColor.clear
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
                                                                    let title: String? = error != nil ? "Error" : "Success"
                                                                    let message: String? = error != nil ? error?.localizedDescription : "Successfully Changed Email"
                                                                    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                                                                    if error != nil {
                                                                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                                                                        alertController.addAction(cancelAction)
                                                                        
                                                                        // Handle Specific Error Codes
                                                                        if let errorCode = FIRAuthErrorCode(rawValue: error!._code) {
                                                                            if errorCode == FIRAuthErrorCode.errorCodeRequiresRecentLogin {
                                                                                alertController.title = "Reauthentication Required"
                                                                                let loginAction = UIAlertAction(title: "Re-Login", style: .destructive, handler: self.signOutAction)
                                                                                alertController.addAction(loginAction)
                                                                            }
                                                                        }
                                                                    }
                                                                    // Successful Update
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
                let updateUsernameAction = UIAlertAction(title: "Update Username", style: .destructive) { action in
                    let textField = alertController.textFields![0]
                    if textField.text?.characters.count ?? 0 > 0 {
                        AppDelegate.usersRef.child(self.userID!).child("settings").child("displayName").setValue(textField.text!)
                        let alertController = UIAlertController(title: "Success",
                                message: "Successfully Changed Username", preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(defaultAction)
                        self.updateDetailsViews()
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default)
                alertController.addTextField()
                alertController.addAction(updateUsernameAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
            // Photo
            else if  indexPath.row == 3 {
                handleTapUserPhoto()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.clear
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
            let displayName = value?["displayName"] as? String
            let fontSize = value?["fontSize"] as? Int ?? AccountDefaultSettings.fontSize
            
            let colorScheme = value?["colorScheme"] as? String ?? AccountDefaultSettings.colorScheme
            let colorSchemeIndex = colorScheme == "light" ? 0 : 1
            let sortingMethod = value?["sortingMethod"] as? String ?? AccountDefaultSettings.sortingMethod
            let sortingMethodIndex = sortingMethod == "date" ? 0 : 1
            
            self.usernameCell.detailTextLabel?.text = displayName
            self.fontSizeSlider.value = Float(fontSize)
            self.colorSchemeSegmentedControl.selectedSegmentIndex = colorSchemeIndex
            self.sortingMethodSegmentedControl.selectedSegmentIndex = sortingMethodIndex
            
            let email = FIRAuth.auth()?.currentUser?.email
            self.emailCell.detailTextLabel?.text = email
            self.passwordCell.detailTextLabel?.text = "******"
            self.colorSchemeSegmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 16)], for: .normal)
            self.sortingMethodSegmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 16)], for: .normal)
            
            if let userPhotoURL = value?["userPhotoURL"] as? String {
                self.userPhotoImageView.loadFromCache(imageURL: userPhotoURL)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func refreshLabelsAfterFontChange() {
        self.emailCell.textLabel?.text = ""
        self.passwordCell.textLabel?.text = ""
        self.usernameCell.textLabel?.text = ""
        
        self.emailCell.textLabel?.text = "Email"
        self.passwordCell.textLabel?.text = "Password"
        self.usernameCell.textLabel?.text = "Username"
    }
    
    @IBAction func fontSliderValueChanged(_ sender: Any) {
        let fontSize = Int(self.fontSizeSlider.value)
        UILabel.appearance().font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        AppDelegate.usersRef.child(userID!).child("settings").child("fontSize").setValue(fontSize)
        fontSizeLabel.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        
        NotificationCenter.default.post(name: Notification.Name(rawValue:"FontSizeChange"),
                                        object: nil)
    }
    
    @IBAction func colorSchemeChanged(_ sender: Any) {
        let colorScheme = self.colorSchemeSegmentedControl.selectedSegmentIndex == 0 ? "light" : "dark"
        AppDelegate.usersRef.child(self.userID!).child("settings").child("colorScheme").setValue(colorScheme)
        
        var textColor:UIColor?
        var tintColor:UIColor?
        var backgroundColor:UIColor?
        
        if colorScheme == "light" {
            textColor = AccountDefaultSettings.lightTextColor
            tintColor = AccountDefaultSettings.lightTintColor
            backgroundColor = AccountDefaultSettings.lightBackgroundColor
        } else if colorScheme == "dark" {
            textColor = AccountDefaultSettings.darkTextColor
            tintColor = AccountDefaultSettings.darkTintColor
            backgroundColor = AccountDefaultSettings.darkBackgroundColor
        }
        
        UILabel.appearance().textColor = textColor!
        UIApplication.shared.delegate?.window??.tintColor = tintColor!
        parent?.navigationController?.navigationBar.barTintColor = backgroundColor!
        UITableView.appearance().backgroundColor = backgroundColor!
        UITableViewCell.appearance().backgroundColor = backgroundColor!
        let settingsVC = parent as! SettingsViewController
        settingsVC.view.backgroundColor = backgroundColor!
        settingsVC.signOutButton.backgroundColor = backgroundColor!
        settingsVC.signOutButton.setTitleColor(UIApplication.shared.delegate?.window??.tintColor, for: UIControlState.normal)
        tableView.tableHeaderView?.backgroundColor = backgroundColor!
        
        self.tableView.reloadData()
    }
    
    @IBAction func sortingMethodChanged(_ sender: Any) {
        let sortingMethod = self.sortingMethodSegmentedControl.selectedSegmentIndex == 0 ? "date" : "popularity"
        AppDelegate.usersRef.child(self.userID!).child("settings").child("sortingMethod").setValue(sortingMethod)
    }
}
