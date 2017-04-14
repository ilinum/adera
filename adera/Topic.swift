//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Topic {
    let creatorUID: String
    let name: String
    var creationDate: String?

    init(creatorUID: String, name: String, creationDate: String) {
        self.creatorUID = creatorUID
        self.name = name
        self.creationDate = creationDate
    }

    init(snapshot: FIRDataSnapshot) {
        self.name = snapshot.childSnapshot(forPath: "name").value as! String
        self.creatorUID = snapshot.childSnapshot(forPath: "creatorUID").value as! String
        self.creationDate = snapshot.childSnapshot(forPath: "creationDate").value as? String
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["name": name, "creatorUID": creatorUID, "creationDate": creationDate!]
    }
}
