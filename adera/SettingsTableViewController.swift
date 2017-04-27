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
import FBSDKLoginKit
import CoreLocation
import Solar

class SettingsTableViewController: UITableViewController, CLLocationManagerDelegate {
    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var passwordCell: UITableViewCell!
    @IBOutlet weak var usernameCell: UITableViewCell!
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var highlightColorSlider: UISlider!
    @IBOutlet weak var colorSchemeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var autoNightThemeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var channelSortingMethodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var topicSortingMethodSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    
    var userID: String?
    var isFacebookUser = false
    let locationManager = CLLocationManager()
    var colorScheme: String?
    let tableViewController: UITableViewController = UITableViewController()
    var channelTV:MyChannelsTableViewDelegate? = nil
    
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
        self.autoNightThemeSegmentedControl.apportionsSegmentWidthsByContent = true
        self.channelSortingMethodSegmentedControl.apportionsSegmentWidthsByContent = true
        self.topicSortingMethodSegmentedControl.apportionsSegmentWidthsByContent = true
        self.channelTV = MyChannelsTableViewDelegate(tableViewController:tableViewController)
        
        if let providerData = FIRAuth.auth()?.currentUser?.providerData {
            for userInfo in providerData {
                switch userInfo.providerID {
                    case "facebook.com":
                        self.isFacebookUser = true
                    default: break
                }
            }
        }
        
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
        // Edit Profile
        if indexPath.section == 2 {
            // Email
            if  indexPath.row == 0 {
                let alertController = UIAlertController(title: "Change Email Address", message: nil, preferredStyle: .alert)
                let updateEmailAction = UIAlertAction(title: "Update Email Address", style: .destructive) { action in
                    let textField = alertController.textFields![0]
                    if textField.text?.characters.count ?? 0 > 0 {
                        FIRAuth.auth()?.currentUser?.updateEmail(textField.text!) { (error) in
                            // Displays Error or Success Message from FireBase
                            let title: String? = error != nil ? "Error" : "Success"
                            let message: String? = error != nil ? error?.localizedDescription : "Successfully Changed Email"
                            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            if error != nil {
                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
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
                let updatePasswordAction = UIAlertAction(title: "Update Password", style: .destructive) { action in
                    let textField = alertController.textFields![0]
                    if textField.text?.characters.count ?? 0 > 0 {
                        FIRAuth.auth()?.currentUser?.updatePassword(textField.text!) { (error) in
                            // Displays Error or Success Message from FireBase
                            let title: String? = error != nil ? "Error" : "Success"
                            let message: String? = error != nil ? error?.localizedDescription : "Successfully Changed Password"
                            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                            if error != nil {
                                let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
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
        headerView.backgroundView?.backgroundColor = UITableView.appearance().backgroundColor
        headerView.textLabel?.textColor = self.view.tintColor
        headerView.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
    }

    func signOutAction(_ sender: Any) {
        let settingsVC = parent as! SettingsViewController
        settingsVC.signOutAction(self)
    }
    
    func updateDetailsViews() {
        // Get Application Settings Values from FireBase
        AppDelegate.usersRef.child(userID!).child("settings").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let displayName = value?["displayName"] as? String
            let fontSize = value?["fontSize"] as? Int ?? AccountDefaultSettings.fontSize
            let highlightColorIndex = value?["highlightColorIndex"] as? Int ?? AccountDefaultSettings.fontSize
            
            let colorScheme = value?["colorScheme"] as? String ?? AccountDefaultSettings.colorScheme
            let autoNightThemeEnabled = value?["autoNightThemeEnabled"] as? Bool ?? AccountDefaultSettings.autoNightThemeEnabled
            let autoNightThemeIndex = autoNightThemeEnabled ? 0 : 1
            let colorSchemeIndex = colorScheme == "light" ? 0 : 1
            let channelSortingMethod = value?["channelSortingMethod"] as? String ?? AccountDefaultSettings.channelSortingMethod
            let channelSortingMethodIndex = channelSortingMethod == "date" ? 0 : 1
            let topicSortingMethod = value?["topicSortingMethod"] as? String ?? AccountDefaultSettings.topicSortingMethod
            let topicSortingMethodIndex = topicSortingMethod == "date" ? 0 : 1
            
            self.usernameCell.detailTextLabel?.text = displayName
            self.fontSizeSlider.value = Float(fontSize)
            self.highlightColorSlider.value = Float(highlightColorIndex)
            self.colorSchemeSegmentedControl.selectedSegmentIndex = colorSchemeIndex
            self.autoNightThemeSegmentedControl.selectedSegmentIndex = autoNightThemeIndex
            self.channelSortingMethodSegmentedControl.selectedSegmentIndex = channelSortingMethodIndex
            self.topicSortingMethodSegmentedControl.selectedSegmentIndex = topicSortingMethodIndex
            
            let email = FIRAuth.auth()?.currentUser?.email
            self.emailCell.detailTextLabel?.text = email
            self.passwordCell.detailTextLabel?.text = "******"
            
            if let userPhotoURL = value?["userPhotoURL"] as? String {
                self.userPhotoImageView.loadFromCache(imageURL: userPhotoURL)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        if isFacebookUser {
            self.emailCell.isUserInteractionEnabled = false
            self.emailCell.textLabel!.isEnabled = false
            self.emailCell.detailTextLabel!.isEnabled = false
            
            self.passwordCell.isUserInteractionEnabled = false
            self.passwordCell.textLabel!.isEnabled = false
            self.passwordCell.detailTextLabel!.isEnabled = false
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
    
    @IBAction func doneChangingFontSize(_ sender: Any) {
        self.tableView.reloadData()
    }
    
    @IBAction func highlightColorValueChanged(_ sender: Any) {
        let colorIndex = Int(self.highlightColorSlider.value)
        let color = AccountDefaultSettings.colors[colorIndex]
        AppDelegate.usersRef.child(self.userID!).child("settings").child("highlightColorIndex").setValue(colorIndex)
        UIApplication.shared.delegate?.window??.tintColor = color
        let settingsVC = parent as! SettingsViewController
        settingsVC.signOutButton.setTitleColor(UIApplication.shared.delegate?.window??.tintColor, for: UIControlState.normal)
    }
    
    @IBAction func doneChangingHighlightColor(_ sender: Any) {
        self.tableView.reloadData()
    }
    
    @IBAction func colorSchemeChanged(_ sender: Any) {
        self.colorScheme = self.colorSchemeSegmentedControl.selectedSegmentIndex == 0 ? "light" : "dark"
        let autoNightThemeEnabled = self.autoNightThemeSegmentedControl.selectedSegmentIndex == 0 ? true : false
        AppDelegate.usersRef.child(self.userID!).child("settings").child("colorScheme").setValue(self.colorScheme)
        if autoNightThemeEnabled && self.colorScheme == "light" {
            self.setAppearanceWithSolar()
        } else {
            self.setAppearance()
        }
    }
    
    @IBAction func autoNightThemeChanged(_ sender: Any) {
        self.colorScheme = self.colorSchemeSegmentedControl.selectedSegmentIndex == 0 ? "light" : "dark"
        let autoNightThemeEnabled = self.autoNightThemeSegmentedControl.selectedSegmentIndex == 0 ? true : false
        AppDelegate.usersRef.child(self.userID!).child("settings").child("autoNightThemeEnabled").setValue(autoNightThemeEnabled)
        if autoNightThemeEnabled && self.colorScheme == "light" {
            self.setAppearanceWithSolar()
        } else {
            self.setAppearance()
        }
    }
    
    @IBAction func channelSortingMethodChanged(_ sender: Any) {
        let channelSortingMethod = self.channelSortingMethodSegmentedControl.selectedSegmentIndex == 0 ? "date" : "popularity"
        AppDelegate.usersRef.child(self.userID!).child("settings").child("channelSortingMethod").setValue(channelSortingMethod)
    }

    @IBAction func topicSortingMethodChanged(_ sender: Any) {
        let topicSortingMethod = self.topicSortingMethodSegmentedControl.selectedSegmentIndex == 0 ? "date" : "popularity"
        AppDelegate.usersRef.child(self.userID!).child("settings").child("topicSortingMethod").setValue(topicSortingMethod)
    }
    
    func setAppearance() {
        var textColor:UIColor?
        var backgroundColor:UIColor?
        
        if self.colorScheme == "light" {
            textColor = AccountDefaultSettings.lightTextColor
            backgroundColor = AccountDefaultSettings.lightBackgroundColor
        } else if self.colorScheme == "dark" {
            textColor = AccountDefaultSettings.darkTextColor
            backgroundColor = AccountDefaultSettings.darkBackgroundColor
        }
        
        UILabel.appearance().textColor = textColor!
        parent?.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: textColor!]
        parent?.navigationController?.navigationBar.barTintColor = backgroundColor!
        UITableView.appearance().backgroundColor = backgroundColor!
        UITableViewCell.appearance().backgroundColor = backgroundColor!
        UITextField.appearance().backgroundColor = backgroundColor!
        UITextView.appearance().backgroundColor = backgroundColor!
        let settingsVC = parent as! SettingsViewController
        settingsVC.view.backgroundColor = backgroundColor!
        settingsVC.signOutButton.backgroundColor = backgroundColor!
        tableView.tableHeaderView?.backgroundColor = backgroundColor!
        
        self.tableView.reloadData()
    }
    
    func setAppearanceWithSolar() {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.requestLocation()
        } else {
            let alert = createErrorAlert(message: "Please enable location services for auto night theme.")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.first!.coordinate
        let solar = Solar(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if (solar!.isDaytime) {
            self.colorScheme = "light"
        } else {
            self.colorScheme = "dark"
        }
        self.setAppearance()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = createErrorAlert(message: error.localizedDescription)
        self.present(alert, animated: true, completion: nil)
    }
}
