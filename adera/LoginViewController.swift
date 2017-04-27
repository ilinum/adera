//
//  ViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/10/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import FBSDKLoginKit
import CoreLocation
import Solar

class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var facebookLoginView: UIView!
    @IBOutlet weak var loginRegisterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    let locationManager = CLLocationManager()
    var fontSize: Int?
    var highlightColorIndex: Int?
    var colorScheme: String?
    private var isLogin: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentUser = FIRAuth.auth()?.currentUser
        if currentUser != nil {
            self.performLogin(user: currentUser!)
        } else {
            // hide keyboard on return and out touches
            usernameTextField.delegate = self
            passwordTextField.delegate = self
            emailTextField.delegate = self
        }
        
        let facebookLoginBtn =  FBSDKLoginButton()
        facebookLoginView.addSubview(facebookLoginBtn)
        facebookLoginBtn.bindFrameToSuperviewBounds()
        
        facebookLoginBtn.delegate = self
        facebookLoginBtn.readPermissions = ["email", "public_profile"]
        
        userPhotoImageView.layer.cornerRadius = 50
        userPhotoImageView.layer.masksToBounds = true
        userPhotoImageView.image = UIImage(named: "DefaultAvatar.png")
        userPhotoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapUserPhoto)))
        userPhotoImageView.isUserInteractionEnabled = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func segmentedControlSwitch(_ sender: Any) {
        isLogin = !isLogin
        if (isLogin) {
            loginButton.title = "Login"
            usernameLabel.isHidden = true
            usernameTextField.isHidden = true
            userPhotoImageView.isHidden = true
        } else {
            loginButton.title = "Register"
            usernameLabel.isHidden = false
            usernameTextField.isHidden = false
            userPhotoImageView.isHidden = false
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        let username = usernameTextField.text
        let password = passwordTextField.text
        let email = emailTextField.text
        let userNameEmpty = !isLogin && (username == nil || username!.characters.count == 0)
        let passwordEmpty = password == nil || password!.characters.count == 0
        let emailEmpty = email == nil || email!.characters.count == 0
        if userNameEmpty ||  passwordEmpty || emailEmpty {
            let alertController = UIAlertController(title: "Error", message: "Please enter data in all fields",
                    preferredStyle: .alert)

            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)

            present(alertController, animated: true, completion: nil)
        } else if (!isLogin) {
            FIRAuth.auth()?.createUser(withEmail: email!, password: password!) { (user, error) in
                if error == nil {
                    let storageRef = FIRStorage.storage().reference().child("user_photos").child(user!.uid).child("avatar.png")
                    if let uploadData = UIImagePNGRepresentation(self.userPhotoImageView.image!) {
                        storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                            if error != nil {
                                print(error ?? "error")
                                return
                            }
                            if let userPhotoURL = metadata?.downloadURL()?.absoluteString {
                                self.setUpNewAccount(userID: user!.uid, username: username!, userPhotoURL: userPhotoURL)
                                self.userPhotoImageView.storeInCache(imageURL: userPhotoURL, image: self.userPhotoImageView.image!)
                            }
                        })
                    }

                    AppDelegate.subscribeToNotifications(user: user!)

                    self.performSegue(withIdentifier: "afterLoginSegue", sender: self)
                } else {
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription,
                            preferredStyle: .alert)

                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)

                    self.present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            FIRAuth.auth()?.signIn(withEmail: email!, password: password!) { (user, error) in
                if error == nil {
                    self.performLogin(user: user!)
                } else {
                    // Tells the user that there is an error and then gets firebase to tell them the error
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func performLogin(user: FIRUser) {
        AppDelegate.subscribeToNotifications(user: user)
        // Get Application Settings Values from FireBase to use for UI changes upon login
        AppDelegate.usersRef.child((FIRAuth.auth()?.currentUser!.uid)!).child("settings").observeSingleEvent(of: .value, with: { (snapshot) in
            let progressHUD = ProgressHUD(text: "Logging In")
            self.view.addSubview(progressHUD)
            
            let value = snapshot.value as? NSDictionary
            self.fontSize = value?["fontSize"] as? Int
            self.highlightColorIndex = value?["highlightColorIndex"] as? Int
            self.colorScheme = value?["colorScheme"] as? String
            let autoNightThemeEnabled = value?["autoNightThemeEnabled"] as? Bool ?? AccountDefaultSettings.autoNightThemeEnabled
            
            self.setAppearance()
            if autoNightThemeEnabled {
                self.setAppearanceWithSolar()
            }
            
            print("You have successfully logged in")
            self.performSegue(withIdentifier: "afterLoginSegue", sender: self)
        }) { (error) in
            print(error.localizedDescription)
            self.performSegue(withIdentifier: "afterLoginSegue", sender: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "afterLoginSegue") {
            if segue.destination is ChannelTopicTableViewController {
                let tableViewController = segue.destination as! ChannelTopicTableViewController
                let channelDelegate = MyChannelsTableViewDelegate(tableViewController: tableViewController)
                tableViewController.delegate = channelDelegate
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("log out")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        
        let accessToken = FBSDKAccessToken.current()
        guard let accessTokenString = accessToken?.tokenString else {
            return
        }
        
        let progressHUD = ProgressHUD(text: "Logging In")
        self.view.addSubview(progressHUD)
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error == nil {
                AppDelegate.usersRef.child(user!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    if !snapshot.hasChild("settings") {
                        self.setUpNewAccount(userID: user!.uid, username: "usernameNotSet", userPhotoURL: "")
                        var username: String?
                        var photoURL: String?
                        
                        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start {
                            (connection, result, error) in
                            if error != nil {
                                print("Failed to start graph request:", error ?? "error")
                                return
                            }
                            let result = result as! NSDictionary
                            username = result.object(forKey: "name") as? String
                            let userID = result.object(forKey: "id") as! String
                            photoURL = "https://graph.facebook.com/\(userID)/picture?type=large"
                            self.setUpCallbackAccountInfo(userID: user!.uid, username: username!, userPhotoURL: photoURL!)
                        }
                    }
                    self.performLogin(user: user!)
                })
            } else {
                // Tells the user that there is an error and then gets firebase to tell them the error
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    func setUpNewAccount(userID: String, username: String, userPhotoURL: String) {
        print("Sign up successful, configuring user settings")
        let settingsRef = AppDelegate.usersRef.child(userID).child("settings")
        settingsRef.child("displayName").setValue(username)
        settingsRef.child("fontSize").setValue(AccountDefaultSettings.fontSize)
        settingsRef.child("colorScheme").setValue(AccountDefaultSettings.colorScheme)
        settingsRef.child("autoNightThemeEnabled").setValue(AccountDefaultSettings.autoNightThemeEnabled)
        settingsRef.child("channelSortingMethod").setValue(AccountDefaultSettings.channelSortingMethod)
        settingsRef.child("topicSortingMethod").setValue(AccountDefaultSettings.topicSortingMethod)
        settingsRef.child("userPhotoURL").setValue(userPhotoURL)
    }
    
    func setUpCallbackAccountInfo(userID: String, username: String, userPhotoURL: String) {
        print("Setting up callback info for username and photoURL")
        let settingsRef = AppDelegate.usersRef.child(userID).child("settings")
        settingsRef.child("displayName").setValue(username)
        settingsRef.child("userPhotoURL").setValue(userPhotoURL)
    }
    
    func setAppearance() {
        let colorScheme = self.colorScheme ?? AccountDefaultSettings.colorScheme
        let fontSize = self.fontSize ?? AccountDefaultSettings.fontSize
        let highlightColorIndex = self.highlightColorIndex ?? AccountDefaultSettings.highlightColorIndex
        
        let tintColor = AccountDefaultSettings.colors[highlightColorIndex]
        var textColor:UIColor?
        var backgroundColor:UIColor?
        
        if colorScheme == "light" {
            textColor = AccountDefaultSettings.lightTextColor
            backgroundColor = AccountDefaultSettings.lightBackgroundColor
        } else if colorScheme == "dark" {
            textColor = AccountDefaultSettings.darkTextColor
            backgroundColor = AccountDefaultSettings.darkBackgroundColor
        }
        
        UILabel.appearance().textColor = textColor!
        UIApplication.shared.delegate?.window??.tintColor = tintColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: textColor!]
        self.navigationController?.navigationBar.barTintColor = backgroundColor!
        UITableView.appearance().backgroundColor = backgroundColor!
        UITableViewCell.appearance().backgroundColor = backgroundColor!
        UITextField.appearance().backgroundColor = backgroundColor!
        UITextView.appearance().backgroundColor = backgroundColor!
        
        UILabel.appearance().font = UIFont.systemFont(ofSize: CGFloat(fontSize))
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

