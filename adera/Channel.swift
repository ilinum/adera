//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class Channel {
    let presentableName: String
    let description: String
    let creatorUID: String
    var topics: [Topic]
    let password: String?
    let channelType: ChannelType
    var numUsers: Int
    var creationDate: Double

    init(presentableName: String, description: String, creatorUID: String, password: String? = nil, numUsers: Int = 1,
         creationDate: Date) {
        self.presentableName = presentableName
        self.description = description
        self.creatorUID = creatorUID
        self.password = password
        self.numUsers = numUsers
        if password == nil {
            channelType = ChannelType.publicType
        } else {
            channelType = ChannelType.privateType
        }
        topics = []
        self.creationDate = creationDate.timeIntervalSince1970
    }

    init(snapshot: FIRDataSnapshot, type: ChannelType) {
        self.presentableName = snapshot.childSnapshot(forPath: "name").value as! String
        self.description = snapshot.childSnapshot(forPath: "description").value as! String
        self.creatorUID = snapshot.childSnapshot(forPath: "creatorUID").value as! String
        self.numUsers = snapshot.childSnapshot(forPath: "numUsers").value as! Int
        self.creationDate = snapshot.childSnapshot(forPath: "creationDate").value as! Double
        channelType = type
        if type == ChannelType.privateType {
            password = snapshot.key
        } else {
            password = nil
        }
        topics = []
        reloadTopics(snapshot: snapshot.childSnapshot(forPath: "topics"))
    }

    func reloadTopics(snapshot: FIRDataSnapshot) {
        topics = []
        for topicSnapshot in snapshot.children {
            topics.append(Topic(snapshot: topicSnapshot as! FIRDataSnapshot))
        }
    }
    
    func addTopic(snapshot: FIRDataSnapshot) {
        topics.append(Topic(snapshot: snapshot))
    }

    // return it's id in firebase
    func id() -> String {
        if password != nil {
            return password!
        } else {
            return presentableName.lowercased()
        }
    }

    func toDictionary() -> Dictionary<String, Any> {
        let dict: Dictionary<String, Any> = ["name": presentableName,
                    "description": description,
                    "creatorUID": creatorUID,
                    "numUsers": numUsers,
                    "topics": topics.map {
                        topic -> Dictionary<String, Any> in
                        return topic.toDictionary()
                    },
                    "creationDate": creationDate]
        return dict
    }

    func setNumUsers(numUsers: Int) {
        self.numUsers = numUsers
        AppDelegate.channelsRefForType(type: channelType).child(id()).child("numUsers").setValue(numUsers)
    }

    class func leaveChannel(channel: Channel!, user: FIRUser) {
        channel.setNumUsers(numUsers: channel.numUsers - 1)
        let id = channel.id()
        let channelTypeStr = channelTypeToString(type: channel.channelType)
        let userRef = AppDelegate.usersRef.child(user.uid)
        let myChannels = userRef.child("channels").child(channelTypeStr)
        myChannels.observeSingleEvent(of: .value, with: { snapshot in
            var newUserChannels: [String] = []
            for child in snapshot.children {
                let chanNameSnap = child as! FIRDataSnapshot
                let chanName = chanNameSnap.value as! String
                if chanName == id {
                    chanNameSnap.ref.removeValue()
                } else {
                    newUserChannels.append(chanName)
                }
            }
        })
        userRef.child("notifications/channels/\(channelTypeStr)/\(channel.id())").removeValue()
        AppDelegate.subscribeToNotifications(user: user)
    }
}
