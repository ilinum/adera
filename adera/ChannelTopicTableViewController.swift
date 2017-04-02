//
//  ChannelTopicTableViewController.swift
//  adera
//
//  Created by Svyatoslav Ilinskiy on 3/18/17.
//  Copyright © 2017 Svyatoslav Ilinskiy. All rights reserved.
//

import UIKit

// this is a generalized view controller for list of topics and list of channels.
// whenever it is created, you should assign it a delegate that should have most of the logic in it.
class ChannelTopicTableViewController: UITableViewController {
    var delegate: ChannelTopicTableViewControllerDelegate? = nil

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
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topicOrTableCell", for: indexPath)
        if delegate != nil {
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer)
            return delegate!.getCellAt(cell: cell as! ChannelTopicCell, index: indexPath)
        } else {
            return cell
        }
    }

    override func numberOfSections(`in` tableView: UITableView) -> Int {
        // if delegate is not-null call it. Otherwise return 0.
        return delegate?.numberOfSections() ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if delegate is not-null call it. Otherwise return 0.
        return delegate?.count(section: section) ?? 0
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
