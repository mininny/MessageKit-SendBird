//
//  ChannelsTableViewController.swift
//  SendBird+MessageKit
//
//  Created by Minhyuk Kim on 2020/03/21.
//  Copyright © 2020 Mininny. All rights reserved.
//

import UIKit
import SendBirdSDK

class ChannelsTableViewController: UITableViewController {
    
    var channels: [SBDGroupChannel] = []
    var channelListQuery: SBDGroupChannelListQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Channels List"
        
        let backItem = UIBarButtonItem(title: "Log Out", style: .done, target: self, action: #selector(signOut))
        self.navigationController?.navigationBar.topItem?.setLeftBarButton(backItem, animated: false)
        navigationController?.barHideOnSwipeGestureRecognizer.isEnabled = false
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.loadChannelListNextPage(false)
    }
    
    @objc func signOut() {
        SBDMain.disconnect {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChatViewController, let channel = sender as? SBDBaseChannel {
            destination.channel = channel
        }
    }
    
    func loadChannelListNextPage(_ refresh: Bool) {
        if refresh {
            self.channelListQuery = nil
        }
        
        if self.channelListQuery == nil {
            self.channelListQuery = SBDGroupChannel.createMyGroupChannelListQuery()
            self.channelListQuery?.order = .latestLastMessage
            self.channelListQuery?.limit = 20
            self.channelListQuery?.includeEmptyChannel = true
        }
        
        if self.channelListQuery?.hasNext == false {
            return
        }
        
        self.channelListQuery?.loadNextPage(completionHandler: { (channels, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
                
                return
            }
            
            DispatchQueue.main.async {
                if refresh {
                    self.channels.removeAll()
                }
                
                self.channels += channels!
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
}

extension ChannelsTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "JoinPublicRoom", for: indexPath)
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelCell", for: indexPath) as? GroupChannelTableViewCell else { return UITableViewCell() }
        cell.configure(with: channels[indexPath.row - 1])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count + 1
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard SBDMain.getCurrentUser() != nil else {
            let alertVC = UIAlertController(title: "Error", message: "You need to be logged in to enter a chat room", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            return
        }
        
        if indexPath.row == 0 {
            let query = SBDOpenChannel.createOpenChannelListQuery()
            query?.channelNameFilter = "TestChannel"
            query?.loadNextPage(completionHandler: { (channel, error) in
                channel?.first?.enter(completionHandler: { (error) in
                    self.performSegue(withIdentifier: "ShowChat", sender: channel?.first)
                })
            })
        } else {
            performSegue(withIdentifier: "ShowChat", sender: self.channels[indexPath.row - 1])
        }
    }
}
