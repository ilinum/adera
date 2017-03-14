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
    private var isLogin: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide keyboard on return
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.delegate = self
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
        } else {
            loginButton.title = "Register"
            usernameLabel.isHidden = false
            usernameTextField.isHidden = false
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

                    AppDelegate.firebaseRef.child("users/\(user!.uid)/username").setValue(username)

//                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "Home")
//                    self.present(vc!, animated: true, completion: nil)

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
                    
                    //Print into the console if successfully logged in
                    print("You have successfully logged in")
                    
//                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "Home")
//                    self.present(vc!, animated: true, completion: nil)
                    
                } else {
                    
                    //Tells the user that there is an error and then gets firebase to tell them the error
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

