//
//  Message.swift
//  SendBird+MessageKit
//
//  Created by Minhyuk Kim on 2020/03/21.
//  Copyright © 2020 Mininny. All rights reserved.
//

import Foundation
import SendBirdSDK
import MessageKit

struct SendBirdMessage: MessageType {
    var messageId: String
    var sender: SenderType { user }
    var user: User
    
    var sentDate: Date { Date(timeIntervalSince1970: Double(self.timestamp / 1000)) }
    var timestamp: Int64
    var kind: MessageKind
    
    private init(kind: MessageKind, user: User, messageId: String, timestamp: Int64) {
        self.kind = kind
        self.user = user
        self.messageId = messageId
        self.timestamp = timestamp
    }
    
    init(with message: SBDBaseMessage?) {
        switch message {
        case let userMessage as SBDUserMessage:
            self.kind = .text(userMessage.message ?? "")
            self.user = User(with: userMessage.sender)
        case let fileMessage as SBDFileMessage:
            self.kind = .text("(\(fileMessage.type))")
            self.user = User(with: fileMessage.sender)
        case let adminMessage as SBDAdminMessage:
            self.kind = .text(adminMessage.message ?? "")
            self.user = User(with: nil)
        default:
            self.kind = .text("Unknown")
            self.user = User(with: nil)
        }
        
        self.messageId = "\(String(describing: message?.messageId))"
        self.timestamp = message?.createdAt ?? 0
    }
}

