//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation

class Message {
    let authorUID: String
    let content: String

    init(authorUID: String, content: String) {
        self.authorUID = authorUID
        self.content = content
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["authorUID": authorUID,
                "content": content]
    }
}
