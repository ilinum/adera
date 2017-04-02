//
//  MyChannelsTableViewDelegate.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/18/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class MyChannelsTableViewDelegate: ChannelTopicTableViewControllerDelegate {
    private let tableViewController: UITableViewController!
    private var publicChannels: [Channel]
    private var privateChannels: [Channel]
    let user: FIRUser = FIRAuth.auth()!.currentUser!

    init(tableViewController: UITableViewController) {
        self.tableViewController = tableViewController
        publicChannels = []
        privateChannels = []
        loadChannels(type: ChannelType.publicType)
        loadChannels(type: ChannelType.privateType)
    }

    func loadChannels(type: ChannelType) {
        let channelTypeStr = channelTypeToString(type: type)
        let userChannelRef = AppDelegate.usersRef.child(user.uid).child("channels").child(channelTypeStr)
        userChannelRef.observe(.value, with: { snapshot in
            var channelNames: [String] = []
            for chan in snapshot.children {
                let name = (chan as! FIRDataSnapshot).value as! String
                channelNames.append(name)
            }
            let firebaseRef = AppDelegate.channelsRefForType(type: type)
            firebaseRef.observeSingleEvent(of: .value, with: { snapshot in
                var newChannels: [Channel] = []
                for chan in snapshot.children {
                    let snap = chan as! FIRDataSnapshot
                    if channelNames.contains(snap.key) {
                        newChannels.append(Channel(snapshot: snap, type: type))
                    }
                }
                if type == ChannelType.publicType {
                    self.publicChannels = newChannels
                } else {
                    assert(type == ChannelType.privateType)
                    self.privateChannels = newChannels
                }
                self.tableViewController.tableView.reloadData()
            })
        })

    }

    func numberOfSections() -> Int {
        var count = 0
        if publicChannels.count > 0 {
            count += 1
        }
        if privateChannels.count > 0 {
            count += 1
        }
        return count
    }

    func count(section: Int) -> Int {
        return getChannelsForSection(section: section).count
    }

    func getCellAt(cell: ChannelTopicCell, index: IndexPath) -> UITableViewCell {
        let channel = getChannelAt(index: index)
        cell.nameLabel.text = channel.presentableName
        cell.descriptionLabel.text = channel.description
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(channelLongPressed))
        cell.addGestureRecognizer(longPressRecognizer)
        return cell
    }

    @objc func channelLongPressed(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.tableViewController.view)
            if let indexPath = tableViewController.tableView.indexPathForRow(at: touchPoint) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                let channel = getChannelAt(index: indexPath)
                if channel.channelType == ChannelType.privateType {
                    alertController.addAction(UIAlertAction(title: "View Channel Password", style: .default, handler: { _ in
                        self.viewChannelPassword(channel: channel)
                    }))
                }
                alertController.addAction(UIAlertAction(title: "Leave Channel", style: .destructive, handler: { _ in
                    self.leaveChannel(channel: channel)
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                tableViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }

    private func viewChannelPassword(channel: Channel!) {
        let vc = tableViewController.storyboard?.instantiateViewController(withIdentifier: "PrivateChannelInfoViewController")
        let privateChannelInfoVC = vc! as! PrivateChannelInfoViewController
        privateChannelInfoVC.channel = channel
        tableViewController.navigationController?.pushViewController(vc!, animated: true)
    }

    private func leaveChannel(channel: Channel!) {
        Channel.leaveChannel(channel: channel, user: user)
    }

    private func getChannelAt(index: IndexPath) -> Channel {
        let channels = getChannelsForSection(section: index.section)
        if index.section == 0 {
            return channels[index.item]
        } else {
            return channels[index.item]
        }
    }

    private func getChannelsForSection(section: Int) -> [Channel] {
        if section == 0 {
            if publicChannels.count == 0 {
                return privateChannels
            } else {
                return publicChannels
            }
        } else {
            return privateChannels
        }
    }

    func getTitle() -> String {
        return "Channels"
    }

    func getLeftBarButtonItem() -> UIBarButtonItem? {
        let add = UIBarButtonSystemItem.add
        return UIBarButtonItem(barButtonSystemItem: add, target: self, action: #selector(createChannelTapped))
    }

    func getRightBarButtonItem() -> UIBarButtonItem? {
        let image = UIImage(named: "Settings-50.png")
        return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(settingsTapped))
    }

    func rowSelected(row: IndexPath) {
        let storyboard = tableViewController.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChannelTopicTableViewController")
        let chanVC = vc! as! ChannelTopicTableViewController
        let channel = getChannelAt(index: row)
        chanVC.delegate = TopicTableViewDelegate(tableViewController: chanVC, channel: channel, user: user)
        tableViewController.navigationController?.pushViewController(chanVC, animated: true)
    }

    @objc func createChannelTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Create Channel", style: .default, handler: createChannel))
        alertController.addAction(UIAlertAction(title: "Browse Public Channels", style: .default, handler: browsePublicChannels))
        alertController.addAction(UIAlertAction(title: "Join Private Channel", style: .default, handler: joinPrivateChannel))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        tableViewController.present(alertController, animated: true, completion: nil)
    }

    func createChannel(alert: UIAlertAction!) {
        tableViewController.performSegue(withIdentifier: "createChannel", sender: tableViewController)
    }

    func browsePublicChannels(alert: UIAlertAction!) {
        let storyboard = tableViewController.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChannelTopicTableViewController")
        let chanVC = vc! as! ChannelTopicTableViewController
        chanVC.delegate = BrowsePublicChannelsTableViewDelegate(tableViewController: chanVC, userChannels: publicChannels,
                user: user)
        tableViewController.navigationController?.pushViewController(chanVC, animated: true)
    }

    func joinPrivateChannel(alert: UIAlertAction!) {
        let storyboard = tableViewController.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "JoinPrivateChannelViewController")
            as! JoinPrivateChannelViewController
        vc.user = user
        tableViewController.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func settingsTapped() {
        let storyboard = tableViewController.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController")
        let settingsVC = vc!
        tableViewController.navigationController?.pushViewController(settingsVC, animated: true)
    }

    func nameForSection(section: Int) -> String? {
        if section == 0 && publicChannels.count > 0 {
            return "Public"
        } else if section <= 1 && privateChannels.count > 0 {
            return "Private"
        }
        return nil
    }
}
