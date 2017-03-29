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
    var channel: Channel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = channel?.name
        passwordLabel.text = channel?.password
    }
}
