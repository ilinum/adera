//
//  PrivateChannelInfoControllerViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/28/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

class PrivateChannelInfoViewController: UIViewController {
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var privateChannelLabel: UILabel!
    
    var channel: Channel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = channel?.presentableName
        passwordLabel.text = channel?.password
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let color = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.blue
        self.privateChannelLabel.textColor = color
        self.passwordLabel.textColor = color
        self.view.backgroundColor = UITableView.appearance().backgroundColor
    }
}
