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
    private var userChannelIds: [String]
    private let user: FIRUser

    init(tableViewController: UITableViewController, userChannels: [Channel], user: FIRUser) {
        self.tableViewController = tableViewController
        self.user = user
        channels = []
        self.userChannelIds = userChannels.map {
            (channel) -> String in
            return channel.id()
        }
        AppDelegate.publicChannelsRef.observe(.value, with: { snapshot in
            var newChannels: [Channel] = []
            for chan in snapshot.children {
                newChannels.append(Channel(snapshot: chan as! FIRDataSnapshot, type: ChannelType.publicType))
            }
            self.channels = newChannels
            self.tableViewController.tableView.reloadData()
        })
    }

    func numberOfSections() -> Int {
        return 1
    }

    func count(section: Int) -> Int {
        return channels.count
    }

    func getCellAt(cell: ChannelTopicCell, index: IndexPath) -> UITableViewCell {
        let channel = channels[index.item]
        if userChannelIds.contains(channel.id()) {
            let imageView = UIImageView(image: UIImage(named: "Delete.png"))
            imageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            imageView.tintImageColor(color: UIColor.red)
            cell.accessoryView = imageView
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(leaveChannel(tapGestureRecognizer:)))
            cell.accessoryView!.isUserInteractionEnabled = true
            cell.accessoryView!.gestureRecognizers = [tapGestureRecognizer]
        } else {
            let color = UIApplication.shared.delegate?.window??.tintColor ?? AccountDefaultSettings.aqua
            let imageView = UIImageView(image: UIImage(named: "Add.png"))
            imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            imageView.tintImageColor(color: color)
            cell.accessoryView = imageView
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(joinChannel(tapGestureRecognizer:)))
            cell.accessoryView!.isUserInteractionEnabled = true
            cell.accessoryView!.gestureRecognizers = [tapGestureRecognizer]
        }
        cell.nameLabel.text = channel.presentableName
        cell.descriptionLabel.text = channel.description
        return cell
    }

    @objc func joinChannel(tapGestureRecognizer: UITapGestureRecognizer) {
        let tapLocation = tapGestureRecognizer.location(in: tableViewController.view)
        let row = tableViewController.tableView.indexPathForRow(at: tapLocation)
        if row != nil {
            let channel = channels[row!.item]
            let id = channel.id()
            channel.setNumUsers(numUsers: channel.numUsers + 1)
            let myPublicChannels = AppDelegate.usersRef.child(user.uid).child("channels").child("public")
            myPublicChannels.childByAutoId().setValue(id)
            userChannelIds.append(id)
            tableViewController.tableView.reloadData()
        }
    }
    
    @objc func leaveChannel(tapGestureRecognizer: UITapGestureRecognizer) {
        let tapLocation = tapGestureRecognizer.location(in: tableViewController.view)
        let row = tableViewController.tableView.indexPathForRow(at: tapLocation)
        if row != nil {
            let channel = channels[row!.item]
            Channel.leaveChannel(channel: channel, user: user)
            userChannelIds.remove(at: userChannelIds.index(of: channel.id())!)
            tableViewController.tableView.reloadData()
        }
    }

    func getTitle() -> String {
        return "Public Channels"
    }

    func getLeftBarButtonItem() -> UIBarButtonItem? {
        return tableViewController.navigationItem.leftBarButtonItem
    }

    func getRightBarButtonItem() -> UIBarButtonItem? {
        return nil
    }

    func rowSelected(row: IndexPath) {
    }

    func nameForSection(section: Int) -> String? {
        return nil
    }
}
