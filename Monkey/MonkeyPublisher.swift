
//
//  MonkeyPublisher.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import OpenTok

class MonkeyPublisher: OTPublisherKit, MonkeyRendererDelegate {
    let view: MonkeyVideoRender
    static let shared = MonkeyPublisher(delegate:nil, settings: OTPublisherSettings())

    override var videoCapture: OTVideoCapture? {
        didSet {
            self.defaultVideoCapture?.removeObserver(self, forKeyPath: "cameraPosition", context: nil)
            self.defaultVideoCapture = nil
            // Save the new instance if it's still compatible with the public contract
            // for defaultVideoCapture
            self.defaultVideoCapture = videoCapture as? MonkeyVideoCapture
            self.defaultVideoCapture?.addObserver(self, forKeyPath: "cameraPosition", options: .new, context: nil)
        }
    }
    override var publishVideo: Bool {
        didSet {
            if !publishVideo {
                self.view.clearBuffer()
            }
        }
    }
    private(set) var defaultVideoCapture: MonkeyVideoCapture?

    override init(delegate: OTPublisherKitDelegate?, settings: OTPublisherKitSettings) {
        self.view = MonkeyVideoRender(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        super.init(delegate: delegate, settings: settings)!
        self.videoCapture = MonkeyVideoCapture()
        // Set mirroring only if the front camera is being used.
        self.view.mirroring = self.defaultVideoCapture?.cameraPosition == .front
        self.videoRender = self.view
    }

    func switchUp() {
        if (self.defaultVideoCapture?.cameraPosition == .front) {
            self.defaultVideoCapture?.cameraPosition = .back
        }
        else {
            self.defaultVideoCapture?.cameraPosition = .front
        }

        self.view.mirroring = self.defaultVideoCapture?.cameraPosition == .front
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if ("cameraPosition" == keyPath) {
            // For example, this is how you could notify a delegate about camera
            // position changes.
        }
    }

    func renderer(_ renderer: MonkeyVideoRender!, didReceive frame: OTVideoFrame!) {

    }
    deinit {
        self.defaultVideoCapture?.removeObserver(self, forKeyPath: "cameraPosition", context: nil)
        defaultVideoCapture = nil
    }
}
