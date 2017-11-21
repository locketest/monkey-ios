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
        // Observe important stream attributes to properly react to changes
        self.stream?.addObserver(self, forKeyPath: "hasVideo", options: .new, context: nil)
        self.stream?.addObserver(self, forKeyPath: "hasAudio", options: .new, context: nil)
    }
    
    deinit {
        self.stream?.removeObserver(self, forKeyPath: "hasVideo", context: nil)
        self.stream?.removeObserver(self, forKeyPath: "hasAudio", context: nil)
    }
    // MARK: - KVO listeners for UI updates
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            if ("hasVideo" == keyPath) {
                // If the video track has gone away, we can clear the screen.
                let value = change?[.newKey] as? Bool
                if value != nil {
                    self.view?.renderingEnabled = true
                } else {
                    self.view?.renderingEnabled = true
                    self.view?.clearBuffer()
                }
            } else if ("hasAudio" == keyPath) {
                // nop?
            }
        }
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
