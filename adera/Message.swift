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
    var location: JSQLocationMediaItem?
    var photoURL: String?
    var mediaItem: JSQPhotoMediaItem?

    init(senderId: String, senderName: String, text: String, date: Date) {
        self.senderName = senderName
        self.senderID = senderId
        self.messageText = text
        self.location = nil
        self.photoURL = nil
        self.mediaItem = nil
        super.init(senderId: senderID, senderDisplayName: senderName, date: date, text: text)
    }

    init(senderId: String, senderName: String, location: JSQLocationMediaItem, date: Date) {
        self.senderID = senderId
        self.senderName = senderName
        self.location = location
        self.messageText = nil
        self.photoURL = nil
        self.mediaItem = nil
        super.init(senderId: senderId, senderDisplayName: senderName, date: date, media: location)
    }
    
    init(senderId: String, senderName: String, photoURL: String, date: Date) {
        self.senderID = senderId
        self.senderName = senderName
        self.photoURL = photoURL
        self.location = nil
        self.messageText = nil
        self.mediaItem = nil
        super.init(senderId: senderId, senderDisplayName: senderName, date: date, text: photoURL)
    }
    
    init(senderId: String, senderName: String, mediaItem: JSQPhotoMediaItem, date: Date) {
        self.senderID = senderId
        self.senderName = senderName
        self.mediaItem = mediaItem
        self.location = nil
        self.messageText = nil
        self.photoURL = nil
        super.init(senderId: senderId, senderDisplayName: senderName, date: date, media: mediaItem)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func toDictionary() -> Dictionary<String, Any> {
        var dict: [String : Any] = ["senderId": senderID!, "timestamp": date.timeIntervalSince1970]
        if messageText != nil {
            dict["text"] = messageText!
        }
        if location != nil {
            let coordinate = location!.location.coordinate
            dict["location"] = ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
        }
        if photoURL != nil {
            dict["photoURL"] = photoURL!
        }
        return dict
    }
}
