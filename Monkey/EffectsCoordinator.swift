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
    var effects = [Effect]()
	
    /// An array of possible effects renderable by received effects messages.
    var effectTypes: [Effect.Type] = [
        PixelationEffect.self,
    ]
	
    weak var chatSession: ChatSession?
	
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
		
    }
    func chatSesssion(_ chatSesssion: ChatSession, connectionCreated connection: OTConnection) {
		
    }
}
