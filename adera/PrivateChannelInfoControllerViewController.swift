//
//  PrivateChannelInfoControllerViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/28/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import QRCode

class PrivateChannelInfoViewController: UIViewController {
    @IBOutlet weak var privateChannelLabel: UILabel!
    @IBOutlet weak var passwordButton: UIButton!
    var channel: Channel? = nil
    @IBOutlet weak var channelQRCodeLabel: UILabel!
    @IBOutlet weak var QRCodeImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = channel?.presentableName
        passwordButton.setTitle(channel!.password, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let color = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.blue
        self.privateChannelLabel.textColor = color
        self.channelQRCodeLabel.textColor = color
        self.view.backgroundColor = UITableView.appearance().backgroundColor
        
        let qrCode = QRCode(channel!.password!)
        self.QRCodeImage.image = qrCode?.image
    }
    
    @IBAction func passwordButtonTapped(_ sender: Any) {
        UIPasteboard.general.string = channel?.password
        let alertController = UIAlertController(title: "", message: "Channel password copied to clipboard!", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
