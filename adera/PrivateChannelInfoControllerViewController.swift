//
//  PrivateChannelInfoControllerViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/28/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

class PrivateChannelInfoViewController: UIViewController {
    @IBOutlet weak var privateChannelLabel: UILabel!
    @IBOutlet weak var passwordButton: UIButton!
    var channel: Channel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = channel?.presentableName
        passwordButton.setTitle(channel?.password, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let color = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.blue
        self.privateChannelLabel.textColor = color
        self.view.backgroundColor = UITableView.appearance().backgroundColor
    }
    
    @IBAction func passwordButtonTapped(_ sender: Any) {
        UIPasteboard.general.string = channel?.password
        let alertController = UIAlertController(title: "", message: "Channel password copied to clipboard!", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
