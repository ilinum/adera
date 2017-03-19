//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class BrowsePublicChannelsTableViewDelegate : ChannelTopicTableViewControllerDelegate {
    private let tableViewController: UITableViewController!
    private var channels: [Channel]
    private var userChannels: [String]
    private let user: FIRUser

    init(tableViewController: UITableViewController, userChannels: [Channel], user: FIRUser) {
        self.tableViewController = tableViewController
        self.user = user
        channels = []
        self.userChannels = userChannels.map {
            (channel) -> String in
            return channel.name
        }
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
        if userChannels.contains(channel.name) {
            cell.accessoryType = .checkmark
            cell.accessoryView = nil
        } else {
            cell.accessoryView = UIImageView(image: UIImage(named: "Plus-50.png"))
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(joinChannel(tapGestureRecognizer:)))
            cell.accessoryView!.isUserInteractionEnabled = true
            cell.accessoryView!.addGestureRecognizer(tapGestureRecognizer)
        }
        cell.nameLabel.text = channel.name
        cell.descriptionLabel.text = channel.description
        return cell
    }

    @objc func joinChannel(tapGestureRecognizer: UITapGestureRecognizer) {
        let tapLocation = tapGestureRecognizer.location(in: tableViewController.view)
        let row = tableViewController.tableView.indexPathForRow(at: tapLocation)
        if row != nil {
            let name = channels[row!.item].name
            let myPublicChannels = AppDelegate.usersRef.child(user.uid).child("channels").child("public")
            myPublicChannels.childByAutoId().setValue(name.lowercased())
            userChannels.append(name)
            tableViewController.tableView.reloadData()
        }
    }

    func getTitle() -> String {
        return "Join Public Channels"
    }

    func getLeftBarButtonItem() -> UIBarButtonItem? {
        return tableViewController.navigationItem.leftBarButtonItem
    }

    func getRightBarButtonItem() -> UIBarButtonItem? {
        return nil
    }

    func rowSelected(row: Int) {
    }
}
