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
    private var messageRef:FIRDatabaseReference?
    private var newMessageRefHandle: FIRDatabaseHandle?
    var channelName:String? = nil
    var topicName:String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chat"
        
        let barButton = UIBarButtonItem()
        barButton.title = "Topics"
        navigationController!.navigationBar.topItem!.backBarButtonItem = barButton
        // Set sender info
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        let name = FIRAuth.auth()?.currentUser?.displayName
        self.senderDisplayName = (name == nil) ? "" : name // make sure username is not nil
        // Get references to current chat topic
        let topicRef = AppDelegate.publicChannelsRef.child(channelName!).child("topics").child(topicName!)
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count;
    }
    // Configure each message/cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "Avatar.jpg"), diameter: 50);
    }
    
    // Message Bubbles
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        // Sets the color of all message bubbles
        if message.senderId == senderId {
            return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        } else {
            return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        }
    }
    
    // Send Button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef?.childByAutoId()
        let messageItem = ["senderId": senderId!, "senderName": senderDisplayName!, "text": text!,]
        itemRef?.setValue(messageItem)
        
        // this will remove the text from the text field
        finishSendingMessage();
        // Play send sound effect
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
    }
    
    // Listen for new messages being written to the Firebase DB
    private func observeMessages() {
        // limits the synchronization to the last 25 messages
        let messageQuery = messageRef?.queryLimited(toLast:25)
        newMessageRefHandle = messageQuery?.observe(.childAdded, with: { (snapshot) -> Void in
        
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                
                // Add Message to data source
                if let message = JSQMessage(senderId: id, displayName: name, text: text) {
                    self.messages.append(message)
                }
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }
}
