//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Channel {
    let name: String
    let description: String
    let creatorUID: String
    var topics: [Topic]

    init(name: String, description: String, creatorUID: String) {
        self.name = name
        self.description = description
        self.creatorUID = creatorUID
        topics = []
    }

    init(snapshot: FIRDataSnapshot) {
        self.name = snapshot.childSnapshot(forPath: "name").value as! String
        self.description = snapshot.childSnapshot(forPath: "description").value as! String
        self.creatorUID = snapshot.childSnapshot(forPath: "creatorUID").value as! String
        topics = []
        for topicSnapshot in snapshot.childSnapshot(forPath: "topics").children {
            topics.append(Topic(snapshot: topicSnapshot as! FIRDataSnapshot))
        }
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["name": name,
                "description": description,
                "creatorUID": creatorUID,
                "topics": topics.map {
                    topic -> Dictionary<String, Any> in
                    return topic.toDictionary()
                }]
    }
}
