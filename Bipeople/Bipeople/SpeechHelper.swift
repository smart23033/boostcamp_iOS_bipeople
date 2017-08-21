//
//  SpeechHelper.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 21..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import AVFoundation

class SpeechHelper: NSObject {
    static let shared: SpeechHelper = .init()
    
    let synth = AVSpeechSynthesizer()
    let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        
        synth.delegate = self
    }
    
    func say(_ utterance: AVSpeechUtterance) {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.duckOthers)
            try audioSession.setActive(true)
            
            if synth.isSpeaking {
                print("Speaking has been stopped");
                synth.stopSpeaking(at: .immediate)
            }
            
            synth.speak(utterance)
        } catch {
            print("\(#function) Error:", error) // FOR DEBUG
        }
    }
}

extension SpeechHelper: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            try audioSession.setActive(false)
        } catch {
            print("\(#function) Error:", error) // FOR DEBUG
        }
    }
}
