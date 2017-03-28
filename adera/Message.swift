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

    init(senderId: String, senderName: String, text: String) {
        self.senderName = senderName
        self.senderID = senderId
        self.messageText = text
        super.init(senderId: senderID, senderDisplayName: senderName, date: Date(), text: text)
    }

    init(snapshot: FIRDataSnapshot) {
        self.senderID = snapshot.childSnapshot(forPath: "senderId").value as! String!
        self.messageText = snapshot.childSnapshot(forPath: "text").value as! String!
        self.senderName = snapshot.childSnapshot(forPath: "senderName").value as! String!
        super.init(senderId: senderID, senderDisplayName: senderName, date: Date(), text:messageText)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func toDictionary() -> Dictionary<String, Any> {
        return ["senderId": senderID!,
                "senderName": senderName!,
                "text": messageText!]
    }
}
