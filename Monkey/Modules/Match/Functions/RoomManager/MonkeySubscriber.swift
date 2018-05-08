//
//  MonkeySubscriber.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class MonkeySubscriber: OTSubscriberKit {
    weak var view: MonkeyVideoRender?
	
    override init?(stream: OTStream, delegate: OTSubscriberKitDelegate?) {
        super.init(stream: stream, delegate: delegate)
        let videoRender = MonkeyVideoRender(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        self.view = videoRender
        self.videoRender = videoRender
    }
	
    override var subscribeToVideo: Bool {
        didSet {
            self.view?.renderingEnabled = self.subscribeToVideo
            if !self.subscribeToVideo {
                self.view?.clearBuffer()
            }
        }
    }
}
