//
//  ChatViewController.swift
//  SendBird+MessageKit
//
//  Created by Minhyuk Kim on 2020/03/20.
//  Copyright © 2020 Mininny. All rights reserved.
//

import UIKit
import SendBirdSDK
import MessageKit
import InputBarAccessoryView
import Alamofire

class ChatViewController: MessagesViewController {
    
    let outgoingAvatarOverlap: CGFloat = 17.5
    
    var messages: [SendBirdMessage] = []
    var channel: SBDBaseChannel?
    
    var hasPrevious: Bool?
    var minMessageTimestamp: Int64 = Int64.max
    var isLoading: Bool = false {
        didSet {
            if self.isLoading == false {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    var refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = channel?.name ?? "Channel"
        
        SBDMain.add(self, identifier: "ChannelDelegate")
        self.loadPreviousMessages(initial: true)
        
        self.configureMessageCollectionView()
        self.messageInputBar.delegate = self
        
        refreshControl.addTarget(self, action: #selector(loadNewMessages), for: .valueChanged)
        self.messagesCollectionView.refreshControl = refreshControl
    }
    
    @objc func loadNewMessages() {
        self.loadPreviousMessages(initial: false)
    }
    
    func configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
//        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        
        // Hide the outgoing avatar and adjust the label alignment to line up with the messages
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        
        // Set outgoing avatar to overlap with the message bubble
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 18, bottom: outgoingAvatarOverlap, right: 0)))
        layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingMessagePadding(UIEdgeInsets(top: -outgoingAvatarOverlap, left: -18, bottom: outgoingAvatarOverlap, right: 18))
        
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 30, height: 30))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    func loadPreviousMessages(initial: Bool) {
        guard !self.isLoading else { return }
        self.isLoading = true
        
        var timestamp: Int64 = 0
        if initial {
            self.hasPrevious = true
            timestamp = Int64.max
        }
        else {
            timestamp = self.minMessageTimestamp
        }
        
        if self.hasPrevious == false {
            self.isLoading = false
            return
        }
        
        guard let channel = self.channel else { return }
        channel.getPreviousMessages(byTimestamp: timestamp, limit: 30, reverse: false, messageType: .all, customType: nil) { (msgs, error) in
            defer {
                self.isLoading = false
            }
            
            guard error == nil else { return }
            guard let messages = msgs, messages.count > 0 else {
                self.hasPrevious = false
                return
            }
            
            if initial {
                (channel as? SBDGroupChannel)?.markAsRead()
                
                DispatchQueue.main.async {
                    self.messages.removeAll()
                    
                    for message in messages.map({ SendBirdMessage(with: $0) }) {
                        self.insertMessage(message, forceScroll: true)
                        
                        if self.minMessageTimestamp > message.timestamp {
                            self.minMessageTimestamp = message.timestamp
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let newMessages = messages.map({ SendBirdMessage(with: $0) })
                    if let minTimestamp = newMessages.map({ $0.timestamp }).min(), self.minMessageTimestamp > minTimestamp {
                        self.minMessageTimestamp = minTimestamp
                    }
                    
                    self.messages.insert(contentsOf: newMessages, at: 0)
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                }
            }
        }
    }
    
    func insertMessage(_ message: SendBirdMessage, forceScroll: Bool = false) {
        messages.append(message)
        
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messages.count - 1])
            if messages.count >= 2 {
                messagesCollectionView.reloadSections([messages.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true || forceScroll {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return self.messages[indexPath.section].user.senderId == self.messages[indexPath.section - 1].user.senderId
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < self.messages.count else { return false }
        return self.messages[indexPath.section].user.senderId == self.messages[indexPath.section + 1].user.senderId
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
}


extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return User(with: SBDMain.getCurrentUser())
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) {
            return NSAttributedString(string: "Delivered", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
}

extension ChatViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isFromCurrentSender(message: message) {
            return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        } else {
            return !isPreviousMessageSameSender(at: indexPath) ? (20 + outgoingAvatarOverlap) : 0
        }
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let sender = message.sender as? User else { return }
        
        sender.getAvatar { [weak self] avatar in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let avatar = avatar else { return }
                avatarView.set(avatar: avatar)
                avatarView.isHidden = self.isNextMessageSameSender(at: indexPath)
                avatarView.layer.borderWidth = 2
                avatarView.layer.borderColor = UIColor.purple.cgColor
            }
        }
    }
}
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = messageInputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
            
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }
        
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()
        
        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        
        self.channel?.sendUserMessage(text, completionHandler: { (userMessage, error) in
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.insertMessages(userMessage)
                self?.messagesCollectionView.scrollToBottom(animated: true)
                self?.messageInputBar.inputTextView.placeholder = ""
            }
        })
    }
    
    private func insertMessages(_ message: SBDBaseMessage?) {
        let message = SendBirdMessage(with: message)
        self.insertMessage(message)
    }
}

extension ChatViewController: SBDChannelDelegate {
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        self.insertMessages(message)
    }
}
