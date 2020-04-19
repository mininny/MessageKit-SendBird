//
//  GroupChannelTableViewCell.swift
//  SendBird+MessageKit
//
//  Created by Minhyuk Kim on 2020/03/23.
//  Copyright © 2020 Mininny. All rights reserved.
//

import UIKit
import SendBirdSDK

class GroupChannelTableViewCell: UITableViewCell {
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var lastUpdatedDateLabel: UILabel!
    
    @IBOutlet weak var memberCountLabel: UILabel!
    @IBOutlet weak var unreadMessageCountLabel: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    func configure(with channel: SBDGroupChannel) {
        if channel.name == "Group Channel" {
            self.channelNameLabel.text = channel.members?.compactMap({ ($0 as? SBDMember)?.userId }).joined(separator: ", ")
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
        
        DispatchQueue.global().async {
            if let url = channel.coverUrl,
                let dataURL = URL(string: url),
                let data = try? Data(contentsOf: dataURL),
                let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            } else {
                if let url = channel.members?.compactMap({ $0 as? SBDMember }).first(where: { $0.profileUrl != nil })?.profileUrl,
                    let dataURL = URL(string: url),
                    let data = try? Data(contentsOf: dataURL),
                    let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                }
            }
        }
        
        self.memberCountLabel.text = "\(channel.memberCount)"
        self.unreadMessageCountLabel.text = "\(channel.unreadMessageCount)"
    }
}
