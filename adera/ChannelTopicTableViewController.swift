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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topicOrTableCell", for: indexPath)
        if delegate != nil {
            return delegate!.getCellAt(cell: cell as! ChannelTopicCell, index: indexPath.item)
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
        return delegate?.count() ?? 0
    }
}

protocol ChannelTopicTableViewControllerDelegate {
    func numberOfSections() -> Int
    func count() -> Int
    func getCellAt(cell: ChannelTopicCell, index: Int) -> UITableViewCell
    func getTitle() -> String
    func getRightBarButtonItem() -> UIBarButtonItem
    func getLeftBarButtonItem() -> UIBarButtonItem
}
