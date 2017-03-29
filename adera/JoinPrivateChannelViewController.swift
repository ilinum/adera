//
//  JoinPrivateChannelViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/29/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class JoinPrivateChannelViewController: UIViewController {
    @IBOutlet weak var passwordTextField: UITextField!
    var user: FIRUser? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func joinChannelButtonTapped(_ sender: Any) {
        let text = passwordTextField.text
        if text == nil || text!.characters.count == 0 {
            createAlert(message: "Please enter channel password")
        } else {
            AppDelegate.privateChannelsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.hasChild(text!) {
                    let userChannels = AppDelegate.usersRef.child(self.user!.uid).child("channels").child("private")
                    userChannels.observeSingleEvent(of: .value, with: { (snapshot) in
                        for chan in snapshot.children {
                            let chanSnap = chan as! FIRDataSnapshot
                            if chanSnap.value as! String! == text {
                                self.createAlert(message: "You are already a member of this channel!")
                                _ = self.navigationController?.popViewController(animated: true)
                                return
                            }
                        }
                        userChannels.childByAutoId().setValue(text)
                        _ = self.navigationController?.popViewController(animated: true)
                    })
                } else {
                    self.createAlert(message: "No private channel with that password")
                }
            })
        }
    }

    private func createAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message,
                preferredStyle: .alert)

        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)

        present(alertController, animated: true, completion: nil)
    }
}
