//
//  AppDelegate.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/10/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase
import FirebaseAuth
import CRToast
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let firebaseRef: FIRDatabaseReference! = FIRDatabase.database().reference()
    static let publicChannelsRef = firebaseRef.child("channels").child("public")
    static let privateChannelsRef = firebaseRef.child("channels").child("private")
    static let usersRef = firebaseRef.child("users")
    static let cache = NSCache<AnyObject, AnyObject>()
    fileprivate static var notificationHandles: [(UInt, FIRDatabaseReference)] = []

    static func channelsRefForType(type: ChannelType) -> FIRDatabaseReference {
        switch (type) {
            case ChannelType.publicType:
                return publicChannelsRef
            case ChannelType.privateType:
                return privateChannelsRef
        }
    }

    static func sanitizeStringForFirebase(_ str: String?) -> String? {
        var res = str
        let badCharacters = ["/", ".", "#", "$", "[", "]"]
        for c in badCharacters {
            res = res?.replacingOccurrences(of: c, with: " ")
        }
        return res
    }
    
    static func subscribeToNotifications(user: FIRUser) {
        for (handle, ref) in notificationHandles {
            ref.removeObserver(withHandle: handle)
        }
        notificationHandles = []
        let topicNotifications = usersRef.child("\(user.uid)/notifications/channels/")
        topicNotifications.observeSingleEvent(of: .value, with: { snapshot in
            let privateSnap = snapshot.childSnapshot(forPath: "private")
            let publicSnap = snapshot.childSnapshot(forPath: "public")
            subscribeToNotificationsForChannel(user: user, snapshot: privateSnap, type: ChannelType.privateType)
            subscribeToNotificationsForChannel(user: user, snapshot: publicSnap, type: ChannelType.publicType)
        })
    }
    
    private static func subscribeToNotificationsForChannel(user: FIRUser, snapshot: FIRDataSnapshot, type: ChannelType) {
        let channelEnumerator = snapshot.children
        while let channel = channelEnumerator.nextObject() as? FIRDataSnapshot {
            let subscribed = channel.childSnapshot(forPath: "subscribed")
            if subscribed.exists() && subscribed.value as! Bool {
                let topicsRef = channelsRefForType(type: type).child("\(channel.key)/topics")
                var sendNotifications = false // hack to avoid bombarding user notifications from .childAdded
                let handle = topicsRef.observe(.childAdded, with: { snapshot in
                    if (sendNotifications) {
                        sendNotification(topicSnap: snapshot, user: user)
                    }
                })
                topicsRef.observeSingleEvent(of: .value, with: { _ in
                    sendNotifications = true
                })
                notificationHandles.append((handle, topicsRef))
            }
            let topicEnumerator = channel.childSnapshot(forPath: "topics").children
            while let topic = topicEnumerator.nextObject() as? FIRDataSnapshot {
                if topic.exists() && topic.value as! Bool {
                    let messageRef = channelsRefForType(type: type).child("\(channel.key)/topics/\(topic.key)/messages")
                    var sendNotifications = false // hack to avoid bombarding user notifications from .childAdded
                    let handle = messageRef.observe(.childAdded, with: { snapshot in
                        if (sendNotifications) {
                            sendNotification(messageSnap: snapshot, user: user)
                        }
                    })
                    messageRef.observeSingleEvent(of: .value, with: { _ in
                        sendNotifications = true
                    })
                    notificationHandles.append((handle, messageRef))
                }
            }
        }
    }
    
    private static func sendNotification(messageSnap: FIRDataSnapshot, user: FIRUser) {
        // todo: send notifications for channels
        let senderID = messageSnap.childSnapshot(forPath: "senderId").value as! String
        if senderID == user.uid {
            // do not show notification for my own messages
            return
        }
        let displayNameSetting = AppDelegate.usersRef.child(senderID).child("settings").child("displayName")
        displayNameSetting.observeSingleEvent(of: .value, with: { displayNameSnapshot in
            let senderName = displayNameSnapshot.value as? String ?? "unknown"
            messageSnap.ref.parent?.parent?.observeSingleEvent(of: .value, with: { topicSnap in
                let topicName = topicSnap.childSnapshot(forPath: "name").value as! String
                topicSnap.ref.parent?.parent?.observeSingleEvent(of: .value, with: { channelSnap in
                    let channelName = channelSnap.childSnapshot(forPath: "name").value as! String

                    let notificationText: String
                    if messageSnap.hasChild("text") {
                        let text = messageSnap.childSnapshot(forPath: "text").value as! String
                        notificationText = "\(senderName) to \(topicName) of \(channelName):\n\(text)"
                    } else if messageSnap.hasChild("location") {
                        notificationText = "\(senderName) shared their location with \(topicName) of \(channelName)"
                    } else {
                        notificationText = "\(senderName) shared a media item with \(topicName) of \(channelName)"
                    }
                    sendNotification(notificationText: notificationText)
                })
            })


        })
    }

    private static func sendNotification(topicSnap: FIRDataSnapshot, user: FIRUser) {
        let senderID = topicSnap.childSnapshot(forPath: "creatorUID").value as! String
        if senderID == user.uid {
            // do not show notification for my own messages
            return
        }
        let displayNameSetting = AppDelegate.usersRef.child(senderID).child("settings").child("displayName")
        displayNameSetting.observeSingleEvent(of: .value, with: { displayNameSnapshot in
            let senderName = displayNameSnapshot.value as? String ?? "unknown"
            let topicName = topicSnap.childSnapshot(forPath: "name").value as! String
            topicSnap.ref.parent?.parent?.observeSingleEvent(of: .value, with: { channelSnap in
                let channelName = channelSnap.childSnapshot(forPath: "name").value as! String
                let notificationText = "\(senderName) created topic \(topicName) in \(channelName)"
                sendNotification(notificationText: notificationText)
            })
        })
    }

    private static func sendNotification(notificationText: String) {
        let backgroundColor = UITableView.appearance().backgroundColor ?? AccountDefaultSettings.lightBackgroundColor
        let textColor = UILabel.appearance().textColor ?? AccountDefaultSettings.lightTextColor
        let font = UILabel.appearance().font ?? UIFont.systemFont(ofSize: 17)
        let options: [AnyHashable: Any] = [
                kCRToastTextKey: notificationText,
                kCRToastTextMaxNumberOfLinesKey: 2,
                kCRToastFontKey: font,
                kCRToastNotificationTypeKey: NSNumber(value: CRToastType.navigationBar.rawValue),
                kCRToastBackgroundColorKey: backgroundColor,
                kCRToastTextColorKey: textColor,
                kCRToastAnimationInTypeKey: (CRToastAnimationType.gravity.rawValue),
                kCRToastAnimationOutTypeKey: (CRToastAnimationType.gravity.rawValue),
                kCRToastAnimationInDirectionKey: (CRToastAnimationDirection.top.rawValue),
                kCRToastAnimationOutDirectionKey: (CRToastAnimationDirection.top.rawValue)
        ]

        CRToastManager.showNotification(options: options, completionBlock: { () -> Void in
            print("toast done!")
        })
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options [UIApplicationOpenURLOptionsKey.annotation])
        return handled
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "adera")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

