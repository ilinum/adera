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

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var loginRegisterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var userPhotoImageView: UIImageView!
    private var isLogin: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        if FIRAuth.auth()?.currentUser != nil {
            self.performLogin()
        } else {
            // hide keyboard on return and out touches
            usernameTextField.delegate = self
            passwordTextField.delegate = self
            emailTextField.delegate = self
        }
        
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
                    print("Sign up successful")

                    let settingsRef = AppDelegate.usersRef.child(user!.uid).child("settings")
                    settingsRef.child("displayName").setValue(username)
                    settingsRef.child("fontSize").setValue(AccountDefaultSettings.fontSize)
                    settingsRef.child("colorScheme").setValue(AccountDefaultSettings.colorScheme)
                    settingsRef.child("sortingMethod").setValue(AccountDefaultSettings.sortingMethod)
                    
                    let storageRef = FIRStorage.storage().reference().child("user_photos").child(user!.uid).child("avatar.png")
                    
                    if let uploadData = UIImagePNGRepresentation(self.userPhotoImageView.image!) {
                        storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                            if error != nil {
                                print(error ?? "error")
                                return
                            }
                            if let userPhotoURL = metadata?.downloadURL()?.absoluteString {
                                settingsRef.child("userPhotoURL").setValue(userPhotoURL)
                                self.userPhotoImageView.storeInCache(imageURL: userPhotoURL, image: self.userPhotoImageView.image!)
                            }
                        })
                    }

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
                    self.performLogin()
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
    
    func performLogin() {
        let progressHUD = ProgressHUD(text: "Logging In")
        self.view.addSubview(progressHUD)
        // Get Application Settings Values from FireBase to use for UI changes upon login
        AppDelegate.usersRef.child((FIRAuth.auth()?.currentUser!.uid)!).child("settings").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let fontSize = value?["fontSize"] as? Int ?? AccountDefaultSettings.fontSize
            let colorScheme = value?["colorScheme"] as? String ?? AccountDefaultSettings.colorScheme
            
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
            self.navigationController?.navigationBar.barTintColor = backgroundColor!
            UITableView.appearance().backgroundColor = backgroundColor!
            UITableViewCell.appearance().backgroundColor = backgroundColor!
            
            UILabel.appearance().font = UIFont.systemFont(ofSize: CGFloat(fontSize))
            
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
}

