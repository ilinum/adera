//
//  ChannelTableViewControllerDelegate.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/18/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

class ChannelTableViewControllerDelegate : ChannelTopicTableViewControllerDelegate {
    private let tableViewController: UITableViewController!
    init(tableViewController: UITableViewController) {
        self.tableViewController = tableViewController
    }

    func numberOfSections() -> Int {
        return 1 //todo
    }

    func count() -> Int {
        return 0 //todo
    }

    func getCellAt(cell: ChannelTopicCell, index: Int) -> UITableViewCell {
        return cell
    }

    func getTitle() -> String {
        return "Channels"
    }

    func getLeftBarButtonItem() -> UIBarButtonItem {
        let add = UIBarButtonSystemItem.add
        return UIBarButtonItem(barButtonSystemItem: add, target: self, action: #selector(createChannelTapped))
    }

    func getRightBarButtonItem() -> UIBarButtonItem {
        let image = UIImage(named: "Settings-50.png")
        return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(settingsTapped))
    }

    @objc func createChannelTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Create Channel", style: .default, handler: createChannel))
        alertController.addAction(UIAlertAction(title: "Browse Public Channels", style: .default, handler: browsePublicChannels))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        tableViewController.present(alertController, animated: true, completion: nil)
    }

    func createChannel(alert: UIAlertAction!) {
        tableViewController.performSegue(withIdentifier: "createChannel", sender: tableViewController)
    }

    func browsePublicChannels(alert: UIAlertAction!) {

    }

    @objc func settingsTapped() {

    }

}
