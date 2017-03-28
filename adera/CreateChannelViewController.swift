//
//  CreateChannelViewController.swift
//  
//
//  Created by Svyatoslav Ilinskiy on 3/18/17.
//
//

import UIKit
import FirebaseAuth
import Firebase

class CreateChannelViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelDescriptionTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        channelNameTextField.delegate = self
        channelDescriptionTextView.delegate = self

        self.title = "Create Channel"
        channelDescriptionTextView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        channelDescriptionTextView.layer.borderWidth = 1.0
        channelDescriptionTextView.layer.cornerRadius = 5
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
    
    @IBAction func createChannelButtonTapped(_ sender: Any) {
        // "/" is bad in firebase. it creates a hierarchy
        // ".#$[]" are also bad. not allowed in child()
        var channelNameText = channelNameTextField.text
        let badCharacters = ["/", ".", "#", "$", "[", "]"]
        for c in badCharacters {
            channelNameText = channelNameText?.replacingOccurrences(of: c, with: " ")
        }
        if channelNameText == nil || channelNameText!.characters.count == 0 {
            let alertController = UIAlertController(title: "Error", message: "Please enter channel name",
                                                    preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            return
        }
        let user = FIRAuth.auth()!.currentUser!
        let description = channelDescriptionTextView.text!
        let channel = Channel(name: channelNameText!, description: description, creatorUID: user.uid)
        AppDelegate.publicChannelsRef.child((channel.name.lowercased())).setValue(channel.toDictionary())

        // join a channel just created
        let publicChannels = AppDelegate.usersRef.child(user.uid).child("channels").child("public")
        publicChannels.childByAutoId().setValue(channel.name.lowercased())

        _ = navigationController?.popViewController(animated: true)
    }
}
