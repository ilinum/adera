//
//  ChannelTopicTableViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/18/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit
import FirebaseAuth
import CoreLocation
import Solar

// this is a generalized view controller for list of topics and list of channels.
// whenever it is created, you should assign it a delegate that should have most of the logic in it.
class ChannelTopicTableViewController: UITableViewController, CLLocationManagerDelegate {
    var delegate: ChannelTopicTableViewControllerDelegate? = nil
    let locationManager = CLLocationManager()
    var colorScheme: String?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if delegate != nil {
            navigationItem.title = delegate!.getTitle()
            self.navigationItem.leftBarButtonItem = delegate!.getLeftBarButtonItem()
            self.navigationItem.rightBarButtonItem = delegate!.getRightBarButtonItem()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = true
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue:"FontSizeChange"),
                                               object: nil,
                                               queue: nil,
                                               using: onContentSizeChange)
        
        AppDelegate.usersRef.child((FIRAuth.auth()?.currentUser?.uid)!).child("settings").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let autoNightThemeEnabled = value?["autoNightThemeEnabled"] as? Bool ?? AccountDefaultSettings.autoNightThemeEnabled
            self.colorScheme = value?["colorScheme"] as? String ?? AccountDefaultSettings.colorScheme
            
            if autoNightThemeEnabled && self.colorScheme == "light" {
                self.setAppearanceWithSolar()
            } else {
                self.setAppearance()
            }
        })
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topicOrTableCell", for: indexPath) as! ChannelTopicCell
        
        // Table view cell label appearances
        cell.nameLabel?.font = UIFont.boldSystemFont(ofSize: UILabel.appearance().font?.pointSize ?? 17)
        cell.nameLabel?.textColor = UILabel.appearance().textColor
        cell.descriptionLabel?.textColor = UIColor.gray
        cell.backgroundColor = UITableViewCell.appearance().backgroundColor
        
        if delegate != nil {
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer)
            return delegate!.getCellAt(cell: cell, index: indexPath)
        } else {
            return cell
        }
    }

    override func numberOfSections(`in` tableView: UITableView) -> Int {
        // if delegate is not-null call it. Otherwise return 0.
        let count = delegate?.numberOfSections() ?? 0
        // Message to display when Channel list is empty
        if count == 0 {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            
            let emptyTable:String = "Tap the + icon to join or create a Channel!"
            let fontSize = CGFloat(17)
            let characterToHighlight: Character = "+"
            let position = emptyTable.indexDistance(of: characterToHighlight)
            let color = UIApplication.shared.delegate?.window??.tintColor ?? AccountDefaultSettings.aqua
            
            let mutableString = NSMutableAttributedString(string: emptyTable, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize), NSForegroundColorAttributeName: UIColor.gray])
            mutableString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location: position!, length: 1))
            mutableString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: fontSize + 10), range: NSRange(location: position!, length: 1))
            
            emptyLabel.attributedText = mutableString
            emptyLabel.textAlignment = NSTextAlignment.center
            self.tableView.backgroundView = emptyLabel
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        else {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
        return count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if delegate is not-null call it. Otherwise return 0.
        let count = delegate?.count(section: section) ?? 0
        // Message to display when Topics list is empty
        if count == 0 {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            
            let emptyTable:String = "No Topics yet.. 😔\nTap the ✍ icon to create a Topic!"
            let fontSize = CGFloat(17)
            
            let mutableString = NSMutableAttributedString(string: emptyTable, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize), NSForegroundColorAttributeName: UIColor.gray])
            
            emptyLabel.attributedText = mutableString
            emptyLabel.numberOfLines = 2
            emptyLabel.textAlignment = NSTextAlignment.center
            self.tableView.backgroundView = emptyLabel
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        }
        else {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
        return count
    }

    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.rowSelected(row: indexPath)
    }
    
    // Adds last line under table view
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        footerView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        return footerView
    }
    
    // Adds last line under table view
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    // Dynamic Cell Heights
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // Dynamic Cell Heights
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // Header Section Height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if delegate?.nameForSection(section: section) != nil {
            return UILabel.appearance().font.pointSize + 10 
        }
        return 0
    }
    
    // Header Section Appearances
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.white
        let color = UIApplication.shared.delegate?.window??.tintColor ?? AccountDefaultSettings.aqua
        headerView.textLabel?.textColor = color
        headerView.backgroundView?.backgroundColor = UITableView.appearance().backgroundColor
        //        headerView.textLabel?.textAlignment = NSTextAlignment.center
        headerView.textLabel?.font = UIFont.boldSystemFont(ofSize: UILabel.appearance().font.pointSize)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return delegate?.nameForSection(section: section)
    }

    override func viewDidDisappear(_ animated: Bool)  {
        super.viewDidDisappear(animated)
        // Remove notification subscription
        NotificationCenter.default.removeObserver(self)
    }

    // When the UI Font changes, reload the table views
    func onContentSizeChange(notification: Notification) {
        tableView.reloadData()
    }
    
    func setAppearance() {
        var textColor:UIColor?
        var backgroundColor:UIColor?
        
        if self.colorScheme == "light" {
            textColor = AccountDefaultSettings.lightTextColor
            backgroundColor = AccountDefaultSettings.lightBackgroundColor
        } else if self.colorScheme == "dark" {
            textColor = AccountDefaultSettings.darkTextColor
            backgroundColor = AccountDefaultSettings.darkBackgroundColor
        }
        
        UILabel.appearance().textColor = textColor!
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: textColor!]
        self.navigationController?.navigationBar.barTintColor = backgroundColor!
        UITableView.appearance().backgroundColor = backgroundColor!
        UITableViewCell.appearance().backgroundColor = backgroundColor!
        
        self.view.backgroundColor = UITableView.appearance().backgroundColor
        self.tableView.backgroundColor = UITableView.appearance().backgroundColor
        
        self.tableView.reloadData()
    }
    
    func setAppearanceWithSolar() {
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.requestLocation()
        } else {
            let alert = createErrorAlert(message: "Please enable location services for auto night theme.")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.first!.coordinate
        let solar = Solar(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if (solar!.isDaytime) {
            self.colorScheme = "light"
        } else {
            self.colorScheme = "dark"
        }
        self.setAppearance()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alert = createErrorAlert(message: error.localizedDescription)
        self.present(alert, animated: true, completion: nil)
    }
}

protocol ChannelTopicTableViewControllerDelegate {
    func numberOfSections() -> Int
    func count(section: Int) -> Int
    func getCellAt(cell: ChannelTopicCell, index: IndexPath) -> UITableViewCell
    func getTitle() -> String
    func getRightBarButtonItem() -> UIBarButtonItem?
    func getLeftBarButtonItem() -> UIBarButtonItem?
    func rowSelected(row: IndexPath)
    func nameForSection(section: Int) -> String?
}
