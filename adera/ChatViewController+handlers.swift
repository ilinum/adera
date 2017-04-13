//
//  ChatViewController+handlers.swift
//  adera
//
//  Created by Nathan Chapman on 4/13/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import Photos
import Firebase

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let storageRef = FIRStorage.storage().reference()
        if let photoRefURL = info[UIImagePickerControllerReferenceURL] as? URL {
            let photoAssets = PHAsset.fetchAssets(withALAssetURLs: [photoRefURL], options: nil)
            let asset = photoAssets.firstObject
            let message = Message(senderId: senderId, senderName: senderDisplayName, photoURL: URLNotSet, date: Date())
            if let key = sendPhotoMessage(message: message) {
                asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                    let imageFileURL = contentEditingInput?.fullSizeImageURL
                    let path = "\(self.senderId!)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoRefURL.lastPathComponent)"
                    storageRef.child("message_photos").child(path).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        self.setImageURL(storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                })
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
