//
//  Sounds.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/15/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import SpriteKit
import AVFoundation
import AudioToolbox

class SoundPlayer {
    static let shared = SoundPlayer()
    private init() {
        player.volume = 1.0
    }
    
    static let failSound = URL(fileURLWithPath: Bundle.main.path(forResource: "fail", ofType: "mp3")!)
    static let messageSound = URL(fileURLWithPath: Bundle.main.path(forResource: "message", ofType: "wav")!)
    static let clockSound = URL(fileURLWithPath: Bundle.main.path(forResource: "clock", ofType: "mp3")!)
    static let winSound = URL(fileURLWithPath: Bundle.main.path(forResource: "win", ofType: "mp3")!)
    static let scoreSound = URL(fileURLWithPath: Bundle.main.path(forResource: "score", ofType: "mp3")!)
    static let magicSound = URL(fileURLWithPath: Bundle.main.path(forResource: "magic", ofType: "m4a")!)
    static let swordSound = URL(fileURLWithPath: Bundle.main.path(forResource: "sword", ofType: "wav")!)
    static let swipeSound = URL(fileURLWithPath: Bundle.main.path(forResource: "swipe", ofType: "wav")!)
    static let todGameSound = URL(fileURLWithPath: Bundle.main.path(forResource: "tod_game", ofType: "wav")!)
    static let clickSound = URL(fileURLWithPath: Bundle.main.path(forResource: "click", ofType: "mp3")!)
    static let whooshSound = URL(fileURLWithPath: Bundle.main.path(forResource: "whoosh", ofType: "wav")!)
    static let callSound = URL(fileURLWithPath: Bundle.main.path(forResource: "call", ofType: "m4a")!)

    func writeCaptureData(_ data: UnsafeMutableRawPointer!, numberOfSamples count: UInt32) {
        print("write \(count)")
    }
    
    func readRenderData(_ data: UnsafeMutableRawPointer!, numberOfSamples count: UInt32) -> UInt32 {
        print("read \(count)")
        return 0
    }
    private let player = AVPlayer()
    
    private let whooshItem = AVPlayerItem(url: SoundPlayer.whooshSound)
    
    func play(sound: Sound) {
//        OTDefaultAudioDevice.shared().isMuted = true
		
        player.replaceCurrentItem(with: self.item(for: sound))
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinish(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinish(_:)),
                                               name: .AVPlayerItemFailedToPlayToEndTime,
                                               object: player.currentItem)
        DispatchQueue.global(qos: .background).async {
            self.player.play()
        }
        
    }
    
    func stopPlayer() {
        self.player.pause()
    }
    
    @objc func playerDidFinish(_ notification: NSNotification) {
        guard let playerItem = notification.object as? AVPlayerItem else {
            return // not ok
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        player.pause()
        player.seek(to: CMTimeMake(0, 1))
        player.replaceCurrentItem(with: nil)
        print("Player did finish")
//        OTDefaultAudioDevice.shared().isMuted = false
    }
    
    private func item(for sound: Sound) -> AVPlayerItem {
        if sound == .whoosh {
            return self.whooshItem
        }
        var soundURL:URL

        switch sound {
        case .fail:
            soundURL = SoundPlayer.failSound
        case .clock:
            soundURL = SoundPlayer.clockSound
        case .win:
            soundURL = SoundPlayer.winSound
        case .score:
            soundURL = SoundPlayer.scoreSound
        case .magic:
            soundURL = SoundPlayer.magicSound
        case .sword:
            soundURL = SoundPlayer.swordSound
        case .swipe:
            soundURL = SoundPlayer.swipeSound
        case .click:
            soundURL = SoundPlayer.clickSound
        case .todGame:
            soundURL = SoundPlayer.todGameSound
        case .message:
            soundURL = SoundPlayer.messageSound
        case .whoosh:
            soundURL = SoundPlayer.whooshSound
        case .call:
            soundURL = SoundPlayer.callSound
        }
        return AVPlayerItem(url: soundURL)
    }
    /*
    var mixerUnit: AudioUnit?
    
    override func setupAudioUnit(_ voice_unit: UnsafeMutablePointer<AudioUnit?>!, playout isPlayout: Bool) -> Bool {
            let isResult = super.setupAudioUnit(voice_unit, playout: isPlayout)
            if isPlayout {
                var mixerDescription = AudioComponentDescription()
                mixerDescription.componentType = kAudioUnitType_Mixer
                mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer
                mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple
                guard let mixerComp = AudioComponentFindNext(nil, &mixerDescription) else {
                    print("Missing mixer comp")
                    return isResult
                }
                AudioComponentInstanceNew(mixerComp, &mixerUnit)
                var status:OSStatus = 0
                status = AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, AudioUnitElement(kOutputBus), &stream_format, UInt32(MemoryLayout.size(ofValue: stream_format)))
                if status != noErr {
                    self.checkAndPrintError(OSStatus(status), function: "setupAudioUnit VolumeControl")
                }
                self.setPlayOutRenderCallback(mixerUnit)
                //disable voip render callback (is this really needed ?)
                var render_callback = AURenderCallbackStruct(inputProc: nil, inputProcRefCon: nil)
                AudioUnitSetProperty(AudioUnit(voice_unit), kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, AudioUnitElement(kOutputBus), &render_callback, UInt32(MemoryLayout.size(ofValue: render_callback)))
                var connection = AudioUnitConnection(sourceAudioUnit: mixerUnit!, sourceOutputNumber: 0, destInputNumber: 0)
                var size: UInt32
                size = UInt32(MemoryLayout.size(ofValue: connection))
                status = AudioUnitSetProperty(AudioUnit(voice_unit), kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, AudioUnitElement(kOutputBus), &connection, size)
                if status != noErr {
                    self.checkAndPrintError(OSStatus(status), function: "setupAudioUnit VolumeControl")
                }
                // Need this when screen lock present.
                var maxFPS: UInt32 = 4096
                AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, UInt32(MemoryLayout.size(ofValue: maxFPS)))
                status = AudioUnitInitialize(mixerUnit!)
                if status != noErr {
                    self.checkAndPrintError(OSStatus(status), function: "setupAudioUnit VolumeControl")
                }
            }
            return isResult
        }
        
        override func disposePlayoutUnit() {
            if let mixerUnit = mixerUnit {
                AudioUnitUninitialize(mixerUnit)
                AudioComponentInstanceDispose(mixerUnit)
                self.mixerUnit = nil
            }
            super.disposePlayoutUnit()
        }
        
        func setPlayoutVolume(_ value: Float) {
            AudioUnitSetParameter(mixerUnit!, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, AudioUnitElement(kOutputBus), value, 0)
        }*/
}
enum Sound:Int {
    case fail = 1
    case clock = 2
    case win = 3
    case score = 4
    case magic = 5
    case sword = 6
    case swipe = 7
    case click = 8
    case todGame = 9
    case message = 10
    case whoosh = 11
    case call = 12
}
