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
    
    init(with sendbirdMessage: SBDUserMessage?) {
        let sender = sendbirdMessage?.sender ?? SBDSender()
        
        self.kind = .text(sendbirdMessage?.message ?? "")
        self.user = User(with: sender)
        self.messageId = "\(sendbirdMessage?.messageId)"
        self.timestamp = sendbirdMessage?.createdAt ?? 0
    }

    init(with sendbirdMessage: SBDBaseMessage) {
        self.init(with: sendbirdMessage as? SBDUserMessage)
    }

    init() {
        self.kind = .text("")
        self.user = User(with: nil)
        self.messageId = ""
        self.timestamp = 0
    }
}

