//
//  LoadingTextLabel.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/27/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import Foundation

class LoadingTextLabel: UILabel {
    private let defaultTicks:[String] = [
        "🍌🍌🐵",
        "🍌🐵🍌",
        "🐵🍌🍌",
        "🍌🍌🍌",
        ]
    private var previousTicks = [String]()
    private var nextTicks:[String] = [
        "🍌🍌🐵",
        "🍌🐵🍌",
        "🐵🍌🍌",
        "🍌🍌🍌",
        ]
    private var ticks:[String] = [
        "🍌🍌🐵",
        "🍌🐵🍌",
        "🐵🍌🍌",
        "🍌🍌🍌",
        ]
    var isTicking = true
    private var currentTick = 0
    private var timer:Timer?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.startLoading()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.startLoading()
    }
    
    private func startLoading() {
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(tickIfNeeded), userInfo: nil, repeats: true)
    }
    func setTicks(bait: String, animal: String) {
        for i in 0...defaultTicks.count - 1 {
            nextTicks[i] = defaultTicks[i]
                .replacingOccurrences(of: "🍌", with: bait)
                .replacingOccurrences(of: "🐵", with: animal)
        }
        ticks = nextTicks
        tick()
    }
    
    func setDefaultTicks() {
		self.isHidden = false
        self.nextTicks = defaultTicks
    }
    
    func setTicksWithArray(ticks:[String]) {
        self.nextTicks = ticks
    }
    
    @objc private func tickIfNeeded() {
        if !isTicking {
            return
        }
        tick()
    }
    func tick() {
        var nextTick:Int
        if currentTick == ticks.count - 1 {
            nextTick = 0
        } else {
            nextTick = currentTick + 1
        }
        self.text = ticks[nextTick]
        if nextTicks[0] != ticks[0] {
            if nextTick == 3 {
                ticks = nextTicks
                nextTick = 2
            }
        }
        currentTick = nextTick
    }
}
extension String {
    func replace(charAt index: Int, with newCharacter: Character) -> String {
        var modifiedString = String()
        for (i, char) in self.enumerated() {
            modifiedString += String((i == index) ? newCharacter : char)
        }
        return modifiedString
    }
    subscript (i: Int) -> Character {
        let index = self.index(self.startIndex, offsetBy: i)
        return self[index]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
}
