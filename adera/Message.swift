//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Message {
    let authorUID: String
    let content: String

    init(authorUID: String, content: String) {
        self.authorUID = authorUID
        self.content = content
    }

    init(snapshot: FIRDataSnapshot) {
        self.authorUID = snapshot.childSnapshot(forPath: "authorUID").value as! String
        self.content = snapshot.childSnapshot(forPath: "content").value as! String
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["authorUID": authorUID,
                "content": content]
    }
}
