//
// Created by Svyatoslav Ilinskiy on 3/19/17.
// Copyright (c) 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import Foundation
import FirebaseDatabase
import JSQMessagesViewController

class Message : JSQMessage {
    var senderID: String?
    var messageText: String?
    var senderName: String?

    init(senderId: String, senderName: String, text: String, date: Date) {
        self.senderName = senderName
        self.senderID = senderId
        self.messageText = text
        super.init(senderId: senderID, senderDisplayName: senderName, date: date, text: text)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["senderId": senderID!, "text": messageText!, "timestamp": date.timeIntervalSince1970]
    }
}
