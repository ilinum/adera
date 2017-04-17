//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class TopicTableViewDelegate: ChannelTopicTableViewControllerDelegate {
    private let tableViewController: UITableViewController!
    private var channel: Channel
    let user: FIRUser
    var sortingMethod:String?
    var dict = [String:Int]()  // dictionary for topicNames and its number of messages
    
    init(tableViewController: UITableViewController, channel: Channel, user: FIRUser) {
        self.tableViewController = tableViewController
        self.channel = channel
        self.user = user
        // Initialize the dictionary containing topicNames:numMessages
        let channelRef = AppDelegate.channelsRefForType(type: self.channel.channelType).child(self.channel.id())
        for topic in channel.topics {
            let messageRef = channelRef.child("topics").child(topic.name.lowercased()).child("messages")
            messageRef.observe(.value, with: { snapshot in
                self.dict[topic.name] = Int(snapshot.childrenCount)
                self.channel.topics.sort(by: self.sortingMethod == "date" ? self.sortTopicsByDate : self.sortTopicsByPopularity)
            })
        }
        // Initialize sorting method and sort topics first before displaying
        let sortTypeRef = AppDelegate.usersRef.child(user.uid).child("settings").child("topicSortingMethod")
        sortTypeRef.observe(.value, with: { snapshot in
            self.sortingMethod = snapshot.value as? String
            self.channel.topics.sort(by: self.sortingMethod == "date" ? self.sortTopicsByDate : self.sortTopicsByPopularity)
            self.tableViewController.tableView.reloadData()
        })

        channelRef.child("topics").observe(.childAdded, with: { _ in
            // this one returns the actual child, need complete topic list, so make another observe request
            channelRef.child("topics").observeSingleEvent(of: .value, with: { snapshot in
                channel.reloadTopics(snapshot: snapshot)
                self.channel.topics.sort(by: self.sortingMethod == "date" ? self.sortTopicsByDate : self.sortTopicsByPopularity)
                self.tableViewController.tableView.reloadData()
            })
        })
    }

    func numberOfSections() -> Int {
        return 1
    }

    func count(section: Int) -> Int {
        return channel.topics.count
    }

    func getCellAt(cell: ChannelTopicCell, index: IndexPath) -> UITableViewCell {
//         Sort topics first
        let topic = channel.topics[index.item]
        cell.nameLabel.text = topic.name
        return cell
    }

    func getTitle() -> String {
        return channel.presentableName
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
                let channelRef = AppDelegate.channelsRefForType(type: self.channel.channelType).child(self.channel.id())
                let topicName = AppDelegate.sanitizeStringForFirebase(textField.text)!
                // Create topic
                let topic = Topic(creatorUID: self.user.uid, name: topicName, creationDate: Date())
                // Set TopicRef in Firebase
                channelRef.child("topics").child(topicName.lowercased()).setValue(topic.toDictionary())
                self.channel.topics.append(topic)
                // sort again whenever a new topic is added
                self.channel.topics.sort(by: self.sortingMethod == "date" ? self.sortTopicsByDate : self.sortTopicsByPopularity)
                self.tableViewController.tableView.reloadData()
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .default)

        alertController.addTextField()

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        tableViewController.present(alertController, animated: true, completion: nil)
    }
    
    func sortTopicsByDate(t1: Topic, t2: Topic) -> Bool {
        return t1.creationDate > t2.creationDate
    }
    
    func sortTopicsByPopularity(t1: Topic, t2: Topic) -> Bool {
        // some topics have no messages. if t1 oe t2 has no messages, skip
        if dict[t1.name] == nil || dict[t2.name] == nil {
            return false
        } else {
            return dict[t1.name]! > dict[t2.name]!
        }
    }
    
    // Segues from Topic to Chat
    func rowSelected(row: IndexPath) {
        let storyboard = tableViewController.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.channel = channel
        vc.topicName = channel.topics[row.item].name
        tableViewController.navigationController?.pushViewController(vc, animated: true)
    }

    func nameForSection(section: Int) -> String? {
        return nil
    }
}

