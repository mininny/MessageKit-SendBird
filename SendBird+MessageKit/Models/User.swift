//
//  User.swift
//  SendBird+MessageKit
//
//  Created by Minhyuk Kim on 2020/03/21.
//  Copyright © 2020 Mininny. All rights reserved.
//

import Foundation
import SendBirdSDK
import MessageKit
import AlamofireImage

struct User: SenderType {
    var senderId: String
    var displayName: String
    var profileURL: URL?
    
    static let imageCache = AutoPurgingImageCache()
    
    init(with sendbirdUser: SBDUser?) {
        self.senderId = sendbirdUser?.userId ?? UUID().uuidString
        self.displayName = sendbirdUser?.userId ?? ""
        self.profileURL = URL(string: sendbirdUser?.profileUrl ?? "")
    }
    
    func getAvatar(completionHandler: ((Avatar?)->Void)?) {
        
        if let image = Self.imageCache.image(withIdentifier: self.senderId) {
            completionHandler?(Avatar(image: image, initials: self.displayName))
            return
        } else {
            guard let profileURL = self.profileURL else {
                completionHandler?(nil)
                return
            }
            
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: profileURL) else {
                    completionHandler?(nil)
                    return
                }
                
                let avatarImage = UIImage(data: data)
                completionHandler?(Avatar(image: avatarImage, initials: self.displayName))
                if let image = avatarImage {
                    Self.imageCache.add(image, withIdentifier: self.displayName)
                }
            }
        }
    }
}
