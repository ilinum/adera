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
    var publicChannels: [Channel]
    var privateChannels: [Channel]
    var sortingMethod:String?
    let user: FIRUser = FIRAuth.auth()!.currentUser!
    

    init(tableViewController: UITableViewController) {
        self.tableViewController = tableViewController
        publicChannels = []
        privateChannels = []
        // initialize sortingMethod
        let userID = FIRAuth.auth()?.currentUser?.uid
        let sortTypeRef = AppDelegate.usersRef.child(userID!).child("settings").child("channelSortingMethod")
        sortTypeRef.observe(.value, with: { snapshot in
            self.sortingMethod = snapshot.value as? String
            let sort = self.sortingMethod == "date" ? self.sortChannelsByDate : self.sortChannelsByPopularity
            self.privateChannels.sort(by: sort)
            self.publicChannels.sort(by: sort)
        })
        // load channels
        loadChannels(type: ChannelType.publicType)
        loadChannels(type: ChannelType.privateType)
    }

    func loadChannels(type: ChannelType) {
        let channelTypeStr = channelTypeToString(type: type)    // public or private
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
                // sort again when a new channel is created
                newChannels.sort(by: self.sortingMethod == "date" ? self.sortChannelsByDate : self.sortChannelsByPopularity)
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

    func sortChannelsByPopularity(c1: Channel, c2: Channel) -> Bool {
        return c1.numUsers > c2.numUsers
    }
    
    func sortChannelsByDate(c1: Channel, c2: Channel) -> Bool {
        return c1.creationDate > c2.creationDate
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
        // sort channels before loading page again
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
                    alertController.addAction(UIAlertAction(title: "View Channel Password/QR Code", style: .default, handler: { _ in
                        self.viewChannelPassword(channel: channel)
                    }))
                }
                let channelNotifications = AppDelegate.usersRef.child("\(user.uid)/notifications/channels/" +
                        "/\(channelTypeToString(type: channel.channelType))/\(channel.id())/subscribed")
                channelNotifications.observeSingleEvent(of: .value, with: { snap in
                    if snap.exists() && snap.value as! Bool {
                        alertController.addAction(UIAlertAction(title: "Unsubscribe from notifications", style: .default, handler: { _ in
                            snap.ref.setValue(false)
                            AppDelegate.subscribeToNotifications(user: self.user)
                        }))
                    } else {
                        alertController.addAction(UIAlertAction(title: "Subscribe to notifications", style: .default, handler: { _ in
                            snap.ref.setValue(true)
                            AppDelegate.subscribeToNotifications(user: self.user)
                        }))
                    }
                    
                    alertController.addAction(UIAlertAction(title: "Leave Channel", style: .destructive, handler: { _ in
                        self.leaveChannel(channel: channel)
                    }))
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    self.tableViewController.present(alertController, animated: true, completion: nil)
                })
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

    // Make sure the channels are sorted when displaying it to user
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
        let image = UIImage(named: "Add.png")
        let scaledIcon = UIImage(cgImage: image!.cgImage!, scale: 6, orientation: image!.imageOrientation)
        let button = UIBarButtonItem(image: scaledIcon, style: .plain, target: self, action: #selector(createChannelTapped))
        return button
    }

    func getRightBarButtonItem() -> UIBarButtonItem? {
        let image = UIImage(named: "Settings.png")
        let scaledIcon = UIImage(cgImage: image!.cgImage!, scale: 5, orientation: image!.imageOrientation)
        let button = UIBarButtonItem(image: scaledIcon, style: .plain, target: self, action: #selector(settingsTapped))
        return button
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
