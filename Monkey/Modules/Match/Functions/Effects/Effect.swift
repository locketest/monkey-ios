//
//  StreamSettings.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

@objc protocol Effect: class {
    var effectName: String { get }
    static var effectName: String { get }
    /// The value of "encoded" must be equatable given any two Effect instances initialized with the same "encoded" value.
    var encoded: String { get }
    init?(encoded: String)
    @objc func process(frame: OTVideoFrame)
}
