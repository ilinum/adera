//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Channel {
    let presentableName: String
    let description: String
    let creatorUID: String
    var topics: [Topic]
    let password: String?

    init(presentableName: String, description: String, creatorUID: String, password: String? = nil) {
        self.presentableName = presentableName
        self.description = description
        self.creatorUID = creatorUID
        self.password = password
        topics = []
    }

    init(snapshot: FIRDataSnapshot, type: ChannelType) {
        self.presentableName = snapshot.childSnapshot(forPath: "name").value as! String
        self.description = snapshot.childSnapshot(forPath: "description").value as! String
        self.creatorUID = snapshot.childSnapshot(forPath: "creatorUID").value as! String
        if type == ChannelType.privateType {
            password = snapshot.key
        } else {
            password = nil
        }
        topics = []
        for topicSnapshot in snapshot.childSnapshot(forPath: "topics").children {
            topics.append(Topic(snapshot: topicSnapshot as! FIRDataSnapshot))
        }
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
                    "topics": topics.map {
                        topic -> Dictionary<String, Any> in
                        return topic.toDictionary()
                    }]
        return dict
    }
}
