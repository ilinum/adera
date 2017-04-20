//
//  SettingsTableViewController+handlers.swift
//  adera
//
//  Created by Nathan Chapman on 4/11/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import Firebase

extension SettingsTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func handleTapUserPhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIImagePickerController.self]).setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 16)], for: .normal)
        UITableViewCell.appearance(whenContainedInInstancesOf: [UIImagePickerController.self]).backgroundColor = UIColor.clear
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        }
        else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            userPhotoImageView.image = selectedImage
        }
        
        self.userPhotoImageView.storeInCache(imageURL: "USER_PHOTO_CHANGE", image: self.userPhotoImageView.image!)
        AppDelegate.usersRef.child(self.userID!).child("settings").child("userPhotoURL").setValue("USER_PHOTO_CHANGE")
        
        let storageRef = FIRStorage.storage().reference().child("user_photos").child(self.userID!).child("avatar.png")
        if let uploadData = UIImagePNGRepresentation(self.userPhotoImageView.image!) {
            storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil { return }
                if let userPhotoURL = metadata?.downloadURL()?.absoluteString {
                    AppDelegate.usersRef.child(self.userID!).child("settings").child("userPhotoURL").setValue(userPhotoURL)
                    self.userPhotoImageView.storeInCache(imageURL: userPhotoURL, image: self.userPhotoImageView.image!)
                }
            })
        }
        
        dismiss(animated: true, completion: nil)
        refreshLabelsAfterFontChange()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        refreshLabelsAfterFontChange()
    }
    
}
