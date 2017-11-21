//
//  SwipeablePresentationController.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/18/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class SwipeablePresentationController: UIPresentationController {
    override var shouldRemovePresentersView: Bool {
        return false
    }
    override var shouldPresentInFullscreen: Bool {
        return true
    }
}
