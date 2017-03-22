//
//  SettingsViewController.swift
//  adera
//
//  Created by Nathan Chapman on 3/22/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func signOutAction(_ sender: Any) {
        print("sign out")
        try! FIRAuth.auth()!.signOut()
        if let storyboard = self.storyboard {
            let vc = storyboard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
            self.present(vc, animated: true, completion: nil)
        }
    }
}
