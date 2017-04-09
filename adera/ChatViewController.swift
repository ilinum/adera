//
//  ChatViewController.swift
//  adera
//
//  Created by Songting Wu on 3/22/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

import FirebaseDatabase
import FirebaseAuth
import Firebase
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    // Array to hold JSQMessages
    private var messages = [JSQMessage]();
    // Set up variables to synchronize with Firebase
    private var messageRef: FIRDatabaseReference?
    private var newMessageRefHandle: FIRDatabaseHandle?
    var channelId: String? = nil
    var topicName: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = topicName!
        self.collectionView.collectionViewLayout.messageBubbleFont = UILabel.appearance().font

        let barButton = UIBarButtonItem()
        barButton.title = "Topics"
        navigationController!.navigationBar.topItem!.backBarButtonItem = barButton

        self.inputToolbar.contentView.leftBarButtonItem = nil

        // Set sender info
        let currentUser = FIRAuth.auth()?.currentUser
        self.senderDisplayName = ""
        if (currentUser != nil) {
            self.senderId = currentUser?.uid
            let displayNameRef = AppDelegate.usersRef.child(currentUser!.uid).child("settings").child("displayName")
            displayNameRef.observeSingleEvent(of: .value, with: { snapshot in
                let name: String? = snapshot.value as? String
                if name != nil {
                    self.senderDisplayName = name! // make sure username is not nil
                }
            })
        }
        // Get references to current chat topic
        let topicRef = AppDelegate.publicChannelsRef.child(channelId!).child("topics").child(topicName!.lowercased())
        messageRef = topicRef.child("messages")
        observeMessages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Collection View Functions
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    // Configure each message/cell
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        // Sets the color of all message texts
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white // my messages
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }

    // Set Avatar
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "DefaultAvatar.png"), diameter: 50);
    }

    // Message Bubbles
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        // Sets the color of all message bubbles
        if message.senderId == senderId {
            return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        } else {
            return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        guard let senderDisplayName = message.senderDisplayName else {
            assertionFailure()
            return nil
        }
        let attrs: [String: Any] = [NSFontAttributeName : UILabel.appearance().font]
        return NSAttributedString(string: senderDisplayName, attributes: attrs)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!,
                                 heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return UILabel.appearance().font.pointSize
    }

    // Send Button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!,
                               senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef?.childByAutoId()
        let messageItem = Message(senderId: senderId, senderName: senderDisplayName, text: text, date: date)
        itemRef?.setValue(messageItem.toDictionary())
        // this will remove the text from the text field
        finishSendingMessage();
        // Play send sound effect
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
    }
    
    private func sortMessageByDate(a: JSQMessage, b: JSQMessage) -> Bool {
        return a.date < b.date
    }

    // Listen for new messages being written to the Firebase DB
    private func observeMessages() {
        // limits the synchronization to the last 25 messages
        let messageQuery = messageRef?.queryLimited(toLast: 25)
        newMessageRefHandle = messageQuery?.observe(.childAdded, with: {(snapshot) in
            let senderID = snapshot.childSnapshot(forPath: "senderId").value as! String!
            let text = snapshot.childSnapshot(forPath: "text").value as! String!
            let timestamp: Double! = snapshot.childSnapshot(forPath: "timestamp").value as! Double!
            let displayNameSetting = AppDelegate.usersRef.child(senderID!).child("settings").child("displayName")
            displayNameSetting.observeSingleEvent(of: .value, with: { (snapshot) in
                let senderName = snapshot.value as! String
                let message = Message(senderId: senderID!, senderName: senderName, text: text!,
                        date: Date(timeIntervalSince1970: timestamp))
                self.messages.append(message)
                self.messages.sort(by: self.sortMessageByDate)
                self.finishReceivingMessage()
            })
        })
    }
}
