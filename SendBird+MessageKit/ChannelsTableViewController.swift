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
        
        self.loadChannelListNextPage(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChatViewController, let channel = sender as? SBDGroupChannel {
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelCell", for: indexPath) as? GroupChannelTableViewCell else { return UITableViewCell() }
        
        cell.configure(with: channels[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowChat", sender: self.channels[indexPath.row])
    }
}


class GroupChannelTableViewCell: UITableViewCell {
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var lastUpdatedDateLabel: UILabel!
    
    @IBOutlet weak var memberCountLabel: UILabel!
    @IBOutlet weak var unreadMessageCountLabel: UILabel!
    
    func configure(with channel: SBDGroupChannel) {
        if channel.name == "Group Channel" {
            self.channelNameLabel.text = channel.members?.map({ $0 as? SBDMember }).reduce(into: "", {
                $0 += $1?.userId ?? ""
            })
        } else {
            self.channelNameLabel.text = channel.name
        }
        
        switch channel.lastMessage {
        case let message as SBDUserMessage:
            self.lastMessageLabel.text = message.message
        case let message as SBDFileMessage:
            self.lastMessageLabel.text = "(\(message.type))"
        case let message as SBDAdminMessage:
            self.lastMessageLabel.text = message.message
        default:
            self.lastMessageLabel.text = "(Empty)"
        }
        
        let lastMessageDateFormatter = DateFormatter()
        lastMessageDateFormatter.dateFormat = "YYYY. MM. d"
        
        if channel.lastMessage != nil {
            self.lastUpdatedDateLabel.text = lastMessageDateFormatter.string(from: Date(timeIntervalSince1970: Double((channel.lastMessage?.createdAt)! / 1000)))
        } else {
            self.lastUpdatedDateLabel.text = lastMessageDateFormatter.string(from: Date(timeIntervalSince1970: Double(channel.createdAt)))
        }
        
        self.memberCountLabel.text = "\(channel.memberCount)"
        self.unreadMessageCountLabel.text = "\(channel.unreadMessageCount)"
    }
}
