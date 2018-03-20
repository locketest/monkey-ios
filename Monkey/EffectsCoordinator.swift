//
//  BlurryModeCoordinator.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class EffectsCoordinator: NSObject, MessageHandler {
    /// Append/Remove/Set to modify the publisher effects. This value will be synced with all other clients.
    var effects = [Effect]() {
        didSet {
//            MonkeyPublisher.shared.view.effects = self.effects
            self.sendEffectsMessage()
        }
    }
    /// An array of possible effects renderable by received effects messages.
    var effectTypes: [Effect.Type] = [
        PixelationEffect.self,
    ]
    /// OpenTok does not guarentee message delivery so keep sending the current effects state so it can catch up if needed.
    var effectsSyncTimer: Timer?
    weak var chatSession: ChatSession? {
        didSet {
            effectsSyncTimer?.invalidate()
            // This value could be anything or even not exist. It helps to recover from messages that aren't delivered.
            effectsSyncTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.sendEffectsMessage), userInfo: nil, repeats: true)
        }
    }
    /// Unique to this MessageHandler.
    var chatSessionMessagingPrefix = "effects"
    func chatSession(_ chatSession: ChatSession, received message: String, from connection: OTConnection, withType type: String) {
        if type == "effects" {
            guard let data = message.asJSON as? Dictionary<String, String> else {
                print("Error: Invalid effect data.")
                return
            }
            var subscriberEffects = [Effect]()
            for effectType in effectTypes {
                let encoded = data[effectType.effectName] ?? ""
                effectType.init(encoded: encoded).then { subscriberEffects.append($0) }
            }
            self.chatSession?.subscriber?.view?.effects = subscriberEffects
        }
    }
    func chatSession(_ chatSession: ChatSession, statusChangedTo status: ChatSessionStatus) {
        if status == .disconnecting {
            effectsSyncTimer?.invalidate()
        }
    }
    func chatSesssion(_ chatSesssion: ChatSession, connectionCreated connection: OTConnection) {
        sendEffectsMessage()
    }
    /// Emits the current effects applied to the publisher to each connection in the session.
    func sendEffectsMessage() {
        var data = [String:String]()
        for effect in effects {
            data[effect.effectName] = effect.encoded
        }
        self.chatSession?.send(message: data.toJSON, from: self, withType: "effects")
    }
    deinit {
        effectsSyncTimer?.invalidate()
    }
}
