
//
//  MonkeyPublisher.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/21/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import OpenTok

class MonkeyPublisher: OTPublisherKit {
    let view: UIView
    static let shared = MonkeyPublisher(delegate:nil, settings: OTPublisherSettings())

    override init(delegate: OTPublisherKitDelegate?, settings: OTPublisherKitSettings) {
        self.view = HWCameraManager.shared().localPreviewView
        super.init(delegate: delegate, settings: settings)!
        self.videoCapture = HWCameraManager.shared()
    }
}
