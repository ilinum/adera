//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class TopicTableViewDelegate: ChannelTopicTableViewControllerDelegate {
    var delegate: TopicTableViewDelegate? = nil
    private let tableViewController: UITableViewController!
    private var channel: Channel
    let user: FIRUser

    init(tableViewController: UITableViewController, channel: Channel, user: FIRUser) {
        self.tableViewController = tableViewController
        self.channel = channel
        self.user = user
    }

    func numberOfSections() -> Int {
        return 1
    }

    func count() -> Int {
        return channel.topics.count
    }

    func getCellAt(cell: ChannelTopicCell, index: Int) -> UITableViewCell {
        let topic = channel.topics[index]
        cell.nameLabel.text = topic.name
        let lastMessage = topic.messages.last
        if lastMessage != nil {
            cell.descriptionLabel.text = lastMessage!.content
        } else {
            cell.descriptionLabel.text = ""
        }
        return cell
    }

    func getTitle() -> String {
        return "\(channel.name): Topics"
    }

    func getLeftBarButtonItem() -> UIBarButtonItem? {
        return tableViewController.navigationItem.leftBarButtonItem // back button
    }

    func getRightBarButtonItem() -> UIBarButtonItem? {
        let add = UIBarButtonSystemItem.compose
        return UIBarButtonItem(barButtonSystemItem: add, target: self, action: #selector(createTopicTapped))
    }

    @objc func createTopicTapped() {
        let alertController = UIAlertController(title: "Create a New Topic", message: nil, preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "OK",
                style: .default) { action in
            let textField = alertController.textFields![0]
            if textField.text?.characters.count ?? 0 > 0 {
                let channelRef = AppDelegate.publicChannelsRef.child(self.channel.name.lowercased())
                let topicName = textField.text!
                let topic = Topic(creatorUID: self.user.uid, name: topicName)
                // Set TopicRef in Firebase
                channelRef.child("topics").child(topicName.lowercased()).setValue(topic.toDictionary())
                self.channel.topics.append(topic)
                self.tableViewController.tableView.reloadData()
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel",
                style: .default)

        alertController.addTextField()

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        tableViewController.present(alertController, animated: true, completion: nil)
    }

    // Segues from Topic to Chat
    func rowSelected(row: Int) {
        let storyboard = tableViewController.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.channelName = channel.name.lowercased()
        vc.topicName = channel.topics[row].name.lowercased()
        tableViewController.navigationController?.pushViewController(vc, animated: true)
    }
}

