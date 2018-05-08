//
//  IncomingCallManager.swift
//  Monkey
//
//  Created by Philip Bernstein on 8/16/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

protocol IncomingCallManagerDelegate:class {
    func incomingCallManager(_ incomingCallManager: IncomingCallManager, shouldShowNotificationFor chatSession:ChatSession) -> Bool
    func incomingCallManager(_ incomingCallManager: IncomingCallManager, didDismissNotificatationFor chatSession:ChatSession)
    func incomingCallManager(_ incomingCallManager: IncomingCallManager, transitionToChatSession chatSession: ChatSession)
}

class IncomingCallManager {
    static let shared:IncomingCallManager = IncomingCallManager()
    weak var delegate:IncomingCallManagerDelegate? {
        willSet {
            guard let chatSession = self.chatSession else {
                return
            }
            if newValue?.incomingCallManager(self, shouldShowNotificationFor: chatSession) == false {
                self.dismissShowingNotificationForChatSession(chatSession)
            }
        }
        didSet {
            self.checkForIncomingCall()
        }
    }
    var incomingCallNotificationToken:NotificationToken?
    weak var showingNotification:CallNotificationView? {
        didSet {
            if showingNotification == nil {
                self.stopCallSound()
            }
        }
    }
    var callTimer:Timer?
    var chatSession:ChatSession?
    var skipCallIds:[String] = []
	init() {
		let realm = try? Realm()
		incomingCallNotificationToken = realm?.objects(RealmCall.self).observe({ [unowned self] (changes) in
			self.checkForIncomingCall()
		})
	}
    
    func checkForIncomingCall() {
        let realm = try? Realm()
        guard let incomingCall = realm?.objects(RealmVideoCall.self).first(where: { (chat) -> Bool in
            let status = chat.status == "WAITING"
            let isNotInitiator = chat.initiator?.user_id != APIController.shared.currentUser?.user_id
            let hasSession = chat.session_id?.isEmpty == false
            return status && isNotInitiator && hasSession
        }) else {
            return
        }
        self.reactToIncomingCall(incomingCall)
    }
    
    func reactToIncomingCall(_ realmCall:RealmVideoCall) {
        
        guard self.delegate != nil, showingNotification == nil, self.skipCallIds.contains(realmCall.chat_id!) != true else {
            return
        }
    
        self.chatSession = self.createChatSession(fromVideoCall: realmCall)
        let chatSession = self.chatSession!
        
        if self.delegate?.incomingCallManager(self, shouldShowNotificationFor: chatSession) == true {
           self.initiateCallTimer()
           self.showingNotification = NotificationManager.shared.showCallNotification(chatSession: chatSession, completion: { [unowned self] (response) in
                if response == .accepted {
                    self.stopCallSound()
                    self.showingNotification?.notificationDescriptionLabel.text = "connecting..."
                    self.showingNotification?.callButton.isJiggling = false
                    self.showingNotification?.callButton.isSpinning = true
                    self.delegate?.incomingCallManager(self, transitionToChatSession: chatSession)
                    self.chatSession = nil
                } else {
                    chatSession.disconnect(.consumed)
                    self.dismissShowingNotificationForChatSession(chatSession)
                }
            self.stopCallSound()
            })
        } 
    }
    
    ///  if user ignore video call , call this func
    func cancelVideoCall(chatsession:ChatSession) {
        if let userID = self.chatSession?.realmCall?.user?.user_id,
            let realm = try? Realm(), let friendShip = realm.objects(RealmFriendship.self).filter("user.user_id = \"\(userID)\"").first ,
        let friendshipID = friendShip.friendship_id{
            let param = [
                "data":[
                    "type":"videocall",
                    "friendship":[
                        "id":friendshipID,
                        "friend_id":userID
                    ]
                ]
            ]
            JSONAPIRequest.init(url: "\(Environment.baseURL)/api/videocall/cancel", method: .post, parameters: param,
                                options: [.header("Authorization", APIController.authorization),])
        }
    }
    
    func createChatSession(fromCall:RealmCall) -> ChatSession? {
        guard let chatId = fromCall.chat_id, let sessionId = fromCall.session_id, let userId = fromCall.initiator?.user_id, let token = fromCall.token else {
            return nil
        }
        
        return ChatSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId,
                           chat: Chat(chat_id: chatId, first_name:fromCall.user?.first_name ?? "Your friend", profile_image_url:fromCall.user?.profile_photo_url, user_id:userId),
                           token: token, loadingDelegate: self, isDialedCall: true)
    }
    
    func createChatSession(fromVideoCall:RealmVideoCall) -> ChatSession? {
        guard let chatId = fromVideoCall.chat_id, let sessionId = fromVideoCall.session_id, let userId = fromVideoCall.initiator?.user_id, let token = fromVideoCall.token else {
            return nil
        }
        
        let chatSession = ChatSession(apiKey: APIController.shared.currentExperiment?.opentok_api_key ?? "45702262", sessionId: sessionId,
                                      chat: Chat(chat_id: chatId, first_name:fromVideoCall.user?.first_name ?? "Your friend", profile_image_url:fromVideoCall.user?.profile_photo_url, user_id:userId),
                                      token: token, loadingDelegate: self, isDialedCall: true)
        chatSession.realmVideoCall = fromVideoCall
        return chatSession
    }
    
    func initiateCallTimer() {
        self.callTimer = Timer(timeInterval: 2.52, target: self, selector: #selector(playCallSound), userInfo: nil, repeats: true)
        RunLoop.main.add(self.callTimer!, forMode: .commonModes)
        self.callTimer?.fire()
    }
    
    @objc func playCallSound() {
        SoundPlayer.shared.play(sound: .call)
    }
    
    func stopCallSound() {
        SoundPlayer.shared.stopPlayer()
        self.callTimer?.invalidate()
        self.callTimer = nil
    }
    func dismissShowingNotificationForChatSession(_ chatSession: ChatSession) {
        guard self.showingNotification?.chatSession == chatSession else {
            // Call not started from notification or a different notification is being displayed
            // This should usually be fine but is an easy place for bugs to pop up.
            return
        }
        self.delegate?.incomingCallManager(self, didDismissNotificatationFor: chatSession)
        self.showingNotification?.dismiss()
        self.showingNotification = nil
    }
}

extension IncomingCallManager:ChatSessionLoadingDelegate {
    /// This should never get called, delegate should be passed off before this happens. If this happens something went horribly wrong, disconnect.
    func presentCallViewController(for chatSession:ChatSession) {
        print("Error: presentCallViewController(for:) should never be called on the incoming call manager.")
    }
    
    func dismissCallViewController(for chatSession:ChatSession) {
        print("Error: dismissCallViewController(for:) should never be called on the incoming call manager.")
    }
    
    func chatSession(_ chatSession: ChatSession, callEndedWithError error:Error?) {
        self.dismissShowingNotificationForChatSession(chatSession)
        self.stopCallSound()
        self.chatSession = nil
//        self.checkForIncomingCall()
    }
    
    func shouldShowConnectingStatus(in chatSession: ChatSession) {
        //  do nothing
    }
}

enum CallResponse {
    case accepted,declined
}
