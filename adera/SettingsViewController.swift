//
//  SettingsViewController.swift
//  adera
//
//  Created by Nathan Chapman on 3/22/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var signOutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        self.signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = true
        self.view.backgroundColor = UITableView.appearance().backgroundColor
        self.signOutButton.backgroundColor = UITableView.appearance().backgroundColor
        self.signOutButton.setTitleColor(UIApplication.shared.delegate?.window??.tintColor, for: UIControlState.normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func signOutAction(_ sender: Any) {
        try! FIRAuth.auth()!.signOut()
        FBSDKLoginManager().logOut()
        if let storyboard = self.storyboard {
            
            let tintColor = AccountDefaultSettings.aqua
            let textColor = AccountDefaultSettings.lightTextColor
            let backgroundColor = AccountDefaultSettings.lightBackgroundColor
            let fontSize = AccountDefaultSettings.fontSize
            
            UILabel.appearance().textColor = textColor
            UIApplication.shared.delegate?.window??.tintColor = tintColor
            self.navigationController?.navigationBar.barTintColor = backgroundColor
            UITableView.appearance().backgroundColor = backgroundColor
            UITableViewCell.appearance().backgroundColor = backgroundColor
            UITextField.appearance().backgroundColor = backgroundColor
            UITextView.appearance().backgroundColor = backgroundColor
            
            UILabel.appearance().font = UIFont.systemFont(ofSize: CGFloat(fontSize))
            
            let vc = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
            self.present(vc, animated: true, completion: nil)
        }
    }
}
