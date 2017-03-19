//
//  ChannelTableViewControllerDelegate.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/18/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ChannelTableViewControllerDelegate : ChannelTopicTableViewControllerDelegate {
    private let tableViewController: UITableViewController!
    private var channels: [Channel]

    init(tableViewController: UITableViewController) {
        self.tableViewController = tableViewController
        channels = []
        AppDelegate.publicChannelsRef.observe(.value, with: { snapshot in
            var newChannels: [Channel] = []
            for chan in snapshot.children {
                newChannels.append(Channel(snapshot: chan as! FIRDataSnapshot))
            }
            self.channels = newChannels
            self.tableViewController.tableView.reloadData()
        })
    }

    func numberOfSections() -> Int {
        return 1
    }

    func count() -> Int {
        return channels.count
    }

    func getCellAt(cell: ChannelTopicCell, index: Int) -> UITableViewCell {
        let channel = channels[index]
        cell.nameLabel.text = channel.name
        cell.descriptionLabel.text = channel.description
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
