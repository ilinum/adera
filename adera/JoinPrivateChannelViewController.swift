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
import AVFoundation
import QRCodeReader

class JoinPrivateChannelViewController: UIViewController, QRCodeReaderViewControllerDelegate {
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var channelPasswordLabel: UILabel!
    var user: FIRUser? = nil
    
    lazy var reader: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode], captureDevicePosition: .back)
            $0.showTorchButton = true
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = UITableView.appearance().backgroundColor
        channelPasswordLabel.textColor = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.blue
    }

    @IBAction func joinChannelButtonTapped(_ sender: Any) {
        let text = passwordTextField.text
        if text == nil || text!.characters.count == 0 {
            let alertController = createErrorAlert(message: "Please enter channel password")
            self.present(alertController, animated: true, completion: nil)
        } else {
            joinPrivateChannel(password: text!)
        }
    }
    
    func joinPrivateChannel(password: String) {
        AppDelegate.privateChannelsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(password) {
                let userChannels = AppDelegate.usersRef.child(self.user!.uid).child("channels").child("private")
                userChannels.observeSingleEvent(of: .value, with: { (snapshot) in
                    for chan in snapshot.children {
                        let chanSnap = chan as! FIRDataSnapshot
                        if chanSnap.value as! String! == password {
                            let alertController = createErrorAlert(message: "You are already a member of this channel!")
                            self.present(alertController, animated: true, completion: nil)
                            self.navigationController?.popViewController(animated: true)
                            return
                        }
                    }
                    userChannels.childByAutoId().setValue(password)
                    _ = self.navigationController?.popViewController(animated: true)
                })
            } else {
                let alertController = createErrorAlert(message: "No private channel with that password")
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func scanQRCode(_ sender: Any) {
        do {
            if try QRCodeReader.supportsMetadataObjectTypes() {
                reader.modalPresentationStyle = .formSheet
                reader.delegate               = self
                reader.completionBlock = { (result: QRCodeReaderResult?) in
                    if let result = result {
                        print("Completion with result: \(result.value) of type \(result.metadataType)")
                        self.joinPrivateChannel(password: result.value)
                    }
                }
                present(reader, animated: true, completion: nil)
            }
        } catch let error as NSError {
            switch error.code {
            case -11852:
                let alert = UIAlertController(title: "Error", message: "This app is not authorized to use Back Camera.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            case -11814:
                let alert = UIAlertController(title: "Error", message: "Reader not supported by the current device", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            default:()
            }
        }
    }
    
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
//        dismiss(animated: true) { [weak self] in
//            let alert = UIAlertController(
//                title: "QRCodeReader",
//                message: String (format:"%@ (of type %@)", result.value, result.metadataType),
//                preferredStyle: .alert
//            )
//            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//            self?.present(alert, animated: true, completion: nil)
//        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
    }
}


func createErrorAlert(message: String) -> UIAlertController {
    let alertController = UIAlertController(title: "Error", message: message,
            preferredStyle: .alert)

    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alertController.addAction(defaultAction)
    
    return alertController
}
