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
import FirebaseDatabase

class CreateChannelViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelDescriptionTextView: UITextView!
    @IBOutlet weak var publicPrivateSegmentedControl: UISegmentedControl!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var channelDescriptionLabel: UILabel!
    
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
        self.view.backgroundColor = UITableView.appearance().backgroundColor
        self.navigationController?.toolbar.barTintColor = UITableView.appearance().backgroundColor
        channelNameLabel.textColor = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.blue
        channelDescriptionLabel.textColor = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.blue
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func getChannelType() -> ChannelType {
        let idx = publicPrivateSegmentedControl.selectedSegmentIndex
        if idx == 0 {
            return ChannelType.publicType
        } else {
            assert(idx == 1)
            return ChannelType.privateType
        }
    }
    
    @IBAction func createChannelButtonTapped(_ sender: Any) {
        // "/" is bad in firebase. it creates a hierarchy
        // ".#$[]" are also bad. not allowed in child()
        var channelNameText = AppDelegate.sanitizeStringForFirebase(channelNameTextField.text)
        if channelNameText == nil || channelNameText!.characters.count == 0 {
            let alertController = UIAlertController(title: "Error", message: "Please enter channel name",
                                                    preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            return
        }
        let channelType = getChannelType()
        let user = FIRAuth.auth()!.currentUser!
        let description = channelDescriptionTextView.text!
        var password: String? = nil
        if channelType == ChannelType.privateType {
            password = randomAlphaNumericString(length: 6)
        }
        let channel = Channel(presentableName: channelNameText!, description: description, creatorUID: user.uid, password: password)
        let channelLocationRef: FIRDatabaseReference
        let channelTypeStr: String = channelTypeToString(type: channelType)
        if channelType == ChannelType.publicType {
            channelLocationRef = AppDelegate.publicChannelsRef
        } else {
            assert(channelType == ChannelType.privateType);
            channelLocationRef = AppDelegate.privateChannelsRef
        }
        channelLocationRef.child((channel.id())).setValue(channel.toDictionary())

        // join a channel just created
        let userChannels = AppDelegate.usersRef.child(user.uid).child("channels").child(channelTypeStr)
        userChannels.childByAutoId().setValue(channel.id())

        if channelType == ChannelType.privateType {

            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PrivateChannelInfoViewController")
            let privateChannelInfoVC = vc! as! PrivateChannelInfoViewController
            privateChannelInfoVC.channel = channel
            let index = navigationController!.viewControllers.count - 1
            navigationController?.viewControllers.insert(privateChannelInfoVC, at: index)
            _ = navigationController?.popViewController(animated: true)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    // straight from Stackoverflow: http://stackoverflow.com/a/33860834/5088644
    func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }

        return randomString
    }
}

enum ChannelType {
    case publicType, privateType
}

func channelTypeToString(type: ChannelType) -> String {
    switch type {
        case ChannelType.publicType:
            return "public"
        case ChannelType.privateType:
            return "private"
    }
}
