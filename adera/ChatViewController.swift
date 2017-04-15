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
import Photos

class ChatViewController: JSQMessagesViewController, CLLocationManagerDelegate {
    var messages = [Message]();
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    private var messageRef: FIRDatabaseReference?
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    var channel: Channel? = nil
    var topicName: String? = nil
    let locationManager = CLLocationManager()
    var sendLocation = false
    var avatars = [String: JSQMessagesAvatarImage]()
    var numMessagesToDisplay: Int?
    var typingRef: FIRDatabaseReference?
    var usersTypingQuery: FIRDatabaseQuery?
    var localUserTyping = false
    let URLNotSet = "URLNOTSET"
    
    var isTyping: Bool {
        get { return localUserTyping }
        set {
            localUserTyping = newValue
            typingRef?.setValue(newValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = topicName!
        self.collectionView.collectionViewLayout.messageBubbleFont = UILabel.appearance().font

        let barButton = UIBarButtonItem()
        barButton.title = "Topics"
        navigationController!.navigationBar.topItem!.backBarButtonItem = barButton
        
        let attachImage = UIImage(named: "Attach.png")
        let scaledAttachImage = UIImage(cgImage: attachImage!.cgImage!, scale: 6, orientation: attachImage!.imageOrientation)
        self.inputToolbar.contentView.leftBarButtonItem.setImage(scaledAttachImage, for: .normal)
        self.inputToolbar.contentView.leftBarButtonItemWidth = CGFloat(21)
        
        let sendImage = UIImage(named: "Send")
        let scaledSendImage = UIImage(cgImage: sendImage!.cgImage!, scale: 6, orientation: sendImage!.imageOrientation)
        self.inputToolbar.contentView.rightBarButtonItem.setImage(scaledSendImage, for: .normal)
        self.inputToolbar.contentView.rightBarButtonItemWidth = CGFloat(21)

        self.numMessagesToDisplay = 25
        
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
        let channelRef = AppDelegate.channelsRefForType(type: channel!.channelType).child(channel!.id())
        let topicRef = channelRef.child("topics").child(topicName!.lowercased())
        usersTypingQuery = topicRef.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
        typingRef = topicRef.child("typingIndicator").child(self.senderId)
        messageRef = topicRef.child("messages")
        messageRef?.observe(.value, with: {(snapshot: FIRDataSnapshot) in
            let numMessages = snapshot.childrenCount
            if Int(numMessages) > self.numMessagesToDisplay! {
                self.showLoadEarlierMessagesHeader = true
            }
        })
        observeMessages(numMessages: numMessagesToDisplay!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = true
        self.collectionView.backgroundColor = UITableView.appearance().backgroundColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages[indexPath.item]
        if message.location != nil {
            let regionDistance:CLLocationDistance = 10000
            let location = message.location!.location.coordinate
            let coordinates = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
            ]
            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            if let username = message.senderName {
                mapItem.name = "\(username)'s Location"
            } else {
                mapItem.name = "User Location"
            }
            mapItem.openInMaps(launchOptions: options)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        return avatars[message.senderId]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        // Sets the color of all message bubbles
        if message.text.containsOnlyEmoji {
            return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.clear)
        } else if message.senderId == senderId {
            let color = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.jsq_messageBubbleBlue()
            return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: color)
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        showLoadEarlierMessagesHeader = false
        messageRef?.observeSingleEvent(of: .value, with: {(snapshot: FIRDataSnapshot) in
            let numMessages = snapshot.childrenCount
            if Int(numMessages) > self.numMessagesToDisplay! {
                self.numMessagesToDisplay = self.numMessagesToDisplay! + 25
                self.automaticallyScrollsToMostRecentMessage = false
                self.removeObservers()
                self.messages.removeAll(keepingCapacity: false)
                self.observeMessages(numMessages: self.numMessagesToDisplay!)
                self.collectionView.reloadData()
            }
            if Int(numMessages) > self.numMessagesToDisplay! {
                self.showLoadEarlierMessagesHeader = true
            }
        })
    }

    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let sheet = UIAlertController(title: "Share Media", message: nil, preferredStyle: .actionSheet)
        if channel?.channelType != ChannelType.publicType {
            let locationAction = UIAlertAction(title: "Send Location", style: .default) { (action) in
                self.sendCurrentLocation()
            }
            sheet.addAction(locationAction)
        }
        let photoAction = UIAlertAction(title: "Send Photo", style: .default) { (action) in
            self.sendPhoto()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(photoAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!,
                               senderDisplayName: String!, date: Date!) {
        isTyping = false
        let messageItem = Message(senderId: senderId, senderName: senderDisplayName, text: text, date: date)
        sendMessage(message: messageItem)
    }
    
    func sendCurrentLocation() {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            sendLocation = true
            self.locationManager.delegate = self
            self.locationManager.requestLocation()
        } else {
            let alert = createErrorAlert(message: "Please enable location services to send location.")
            self.present(alert, animated: true, completion: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if sendLocation {
            sendLocation(location: buildLocationItem(forLocation: locations.first!))
            sendLocation = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = createErrorAlert(message: error.localizedDescription)
        self.present(alert, animated: true, completion: nil)
        sendLocation = false
    }

    func buildLocationItem(forLocation location: CLLocation) -> JSQLocationMediaItem {
        let locationItem = JSQLocationMediaItem()
        locationItem.setLocation(location) {
            self.collectionView!.reloadData()
        }
        return locationItem
    }

    func sendLocation(location: JSQLocationMediaItem) {
        let message = Message(senderId: senderId, senderName: senderDisplayName, location: location, date: Date())
        sendMessage(message: message)
    }
    
    func sendMessage(message: Message) {
        let itemRef = messageRef?.childByAutoId()
        itemRef?.setValue(message.toDictionary())
        self.automaticallyScrollsToMostRecentMessage = true
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
    }
    
    func sendPhotoMessage(message: Message) -> String? {
        let itemRef = messageRef?.childByAutoId()
        itemRef?.setValue(message.toDictionary())
        self.automaticallyScrollsToMostRecentMessage = true
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        return itemRef?.key
    }
    
    func sendPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        present(picker, animated: true, completion:nil)
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef?.child(key)
        itemRef?.updateChildValues(["photoURL": url])
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        if let cachedImage = AppDelegate.cache.object(forKey: photoURL as AnyObject) as? UIImage {
            mediaItem.image = cachedImage
            self.collectionView.reloadData()
            guard key != nil else {
                return
            }
            self.photoMessageMap.removeValue(forKey: key!)
            return
        }
        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                mediaItem.image = UIImage.init(data: data!)
                AppDelegate.cache.setObject(mediaItem.image, forKey: photoURL as AnyObject)
                self.collectionView.reloadData()
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    
    private func sortMessageByDate(a: JSQMessage, b: JSQMessage) -> Bool {
        return a.date < b.date
    }
    
    func setupAvatarForMessage(userPhotoURL: String, messageId: String) {
        if let cachedImage = AppDelegate.cache.object(forKey: userPhotoURL as AnyObject) as? UIImage {
            let userAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: cachedImage, diameter: 30)
            self.avatars[messageId] = userAvatar
            self.collectionView.reloadData()
            return
        }
        
        let url = URL(string: userPhotoURL)
        let request = URLRequest(url: url!)
        let dataTask = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if error != nil { return }
            DispatchQueue.main.async {
                if let networkImage = UIImage(data: data!) {
                    AppDelegate.cache.setObject(networkImage, forKey: userPhotoURL as AnyObject)
                    let userAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: networkImage, diameter: 30)
                    self.avatars[messageId] = userAvatar
                    self.collectionView.reloadData()
                }
            }
        }
        dataTask.resume()
    }
    
    func checkForUserPhoto(id: String) {
        AppDelegate.usersRef.child(id).child("settings").child("userPhotoURL").observeSingleEvent(of: .value, with: { (userPhotoURLSnapshot) in
            if let userPhotoURL = userPhotoURLSnapshot.value as? String {
                self.setupAvatarForMessage(userPhotoURL: userPhotoURL, messageId: id)
            }
        })
    }

    private func observeMessages(numMessages: Int) {
        let messageQuery = messageRef?.queryLimited(toLast: UInt(numMessages))
        newMessageRefHandle = messageQuery?.observe(.childAdded, with: {(snapshot: FIRDataSnapshot) in
            let senderID = snapshot.childSnapshot(forPath: "senderId").value as! String!
            let timestamp: Double! = snapshot.childSnapshot(forPath: "timestamp").value as! Double!
            let date = Date(timeIntervalSince1970: timestamp)
            let displayNameSetting = AppDelegate.usersRef.child(senderID!).child("settings").child("displayName")
            self.checkForUserPhoto(id: senderID!)
            displayNameSetting.observeSingleEvent(of: .value, with: { (displayNameSnapshot) in
                let senderName = displayNameSnapshot.value as! String
                var message: Message?
                if snapshot.hasChild("text") {
                    let text = snapshot.childSnapshot(forPath: "text").value as! String!
                    message = Message(senderId: senderID!, senderName: senderName, text: text!, date: date)
                } else if snapshot.hasChild("location") {
                    let locationSnapshot = snapshot.childSnapshot(forPath: "location")
                    let latitude = locationSnapshot.childSnapshot(forPath: "latitude").value as! Double
                    let longitude = locationSnapshot.childSnapshot(forPath: "longitude").value as! Double
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    let locationItem = self.buildLocationItem(forLocation: location)
                    message = Message(senderId: senderID!, senderName: senderName, location: locationItem, date: date)
                } else if snapshot.hasChild("photoURL") {
                    let photoURL = snapshot.childSnapshot(forPath: "photoURL").value as! String!
                    if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: senderID == self.senderId) {
                        message = Message(senderId: senderID!, senderName: senderName, mediaItem: mediaItem, date: date)
                        if photoURL!.hasPrefix("gs://") {
                            self.fetchImageDataAtURL(photoURL!, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                        }
                        if (mediaItem.image == nil) {
                            self.photoMessageMap[snapshot.key] = mediaItem
                        }
                    }
                }
                self.messages.append(message!)
                self.messages.sort(by: self.sortMessageByDate)
                self.finishReceivingMessage()
            })
        })
        updatedMessageRefHandle = messageRef?.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            if snapshot.hasChild("photoURL") {
                let photoURL = snapshot.childSnapshot(forPath: "photoURL").value as! String!
                if let mediaItem = self.photoMessageMap[key] {
                    if photoURL!.hasPrefix("gs://") {
                        self.fetchImageDataAtURL(photoURL!, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                    }
                }
            }
        })
    }
    
    func removeObservers() {
        if let refHandle = newMessageRefHandle {
            messageRef?.removeObserver(withHandle: refHandle)
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef?.removeObserver(withHandle: refHandle)
        }
    }
    
    private func observeTyping() {
        typingRef?.onDisconnectRemoveValue()
        usersTypingQuery?.observe(.value) { (data: FIRDataSnapshot) in
            if data.childrenCount == 1 && self.isTyping {
                self.showTypingIndicator = false
                return
            }
            self.showTypingIndicator = data.childrenCount > 0
        }
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
    
    deinit {
        removeObservers()
    }
}
