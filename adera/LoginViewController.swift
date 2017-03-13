//
//  ViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/10/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var loginRegisterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    private var isLogin: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide keyboard on return
        usernameTextField.delegate = self
        passwordTextField.delegate = self
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
            profilePictureImageView.isHidden = true
        } else {
            loginButton.title = "Register"
            profilePictureImageView.isHidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

