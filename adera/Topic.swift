//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Topic {
    let creatorUID: String
    let name: String
    var messages: [Message]

    init(creatorUID: String, name: String) {
        self.creatorUID = creatorUID
        self.name = name
        messages = []
    }

    init(snapshot: FIRDataSnapshot) {
        self.name = snapshot.childSnapshot(forPath: "name").value as! String
        self.creatorUID = snapshot.childSnapshot(forPath: "creatorUID").value as! String
        messages = []
        for messageSnap in snapshot.childSnapshot(forPath: "messages").children {
            messages.append(Message(snapshot: messageSnap as! FIRDataSnapshot))
        }
    }

    func addMessage(message: Message) {
        messages.append(message)
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["name": name,
                "creatorUID": creatorUID,
                "messages": messages.map {
                    (message) -> Dictionary<String, Any> in
                    return message.toDictionary()
                }]
    }
}
