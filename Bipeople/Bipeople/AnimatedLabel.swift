//
//  AnimatedLabel.swift
//  SampleAnimatedLabel
//
//  Created by 김성준 on 2017. 8. 24..
//  Copyright © 2017년 김성준. All rights reserved.
//

import UIKit

enum DecimalPoints {
    case zero, one
    
    var format: String {
        switch self {
        case .zero: return "%.0f"
        case .one: return "%.1f"
        }
    }
}

class AnimatedLabel: UILabel {
    
    var lastUpdate: TimeInterval = 0
    var progress: TimeInterval = 0
    var destinationValue: Float = 0
    var totalTime: TimeInterval = 0
    var timer: CADisplayLink?
    var decimalPoints: DecimalPoints = .one
    
    var currentValue: Float {
        if progress >= totalTime { return destinationValue }
        return (Float(progress / totalTime) * (destinationValue))
    }
    
    func count(to: Float, duration: TimeInterval = 2.0) {
        
        destinationValue = to
        lastUpdate = Date.timeIntervalSinceReferenceDate
        totalTime = duration
        
        timer?.invalidate()
        timer = nil
        
        addDisplayLink()
    }
    
    func addDisplayLink() {
        timer = CADisplayLink(target: self, selector: #selector(self.updateValue(timer:)))
        timer?.add(to: .main, forMode: .defaultRunLoopMode)
    }
    
    @objc func updateValue(timer: Timer) {
        let now: TimeInterval = Date.timeIntervalSinceReferenceDate
        progress += now - lastUpdate
        lastUpdate = now
        
        if progress >= totalTime {
            self.timer?.invalidate()
            self.timer = nil
            progress = totalTime
        }
        
        setTextValue(value: currentValue)
    }
    
    func setTextValue(value: Float) {
        text = String(format: "%.0f", value)
    }
    
}

