//
//  HistoryChartViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

// TODO: 리펙토링 - 스위치 on off 별로 properties 세팅하기

import UIKit
import FSCalendar

enum CalendarSwitch {
    case on, off
}

class HistoryChartViewController: UIViewController, FSCalendarDelegate {
   
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    
    var startSwitch = CalendarSwitch.off
    var endSwitch = CalendarSwitch.off
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.calendar.today = nil
        self.calendar.isHidden = true
        
    }
    
    @IBAction func didTapStartLabel(_ sender: UITapGestureRecognizer) {
        if endSwitch == .on {
            self.calendar.isHidden = false
            startSwitch = .on
            endSwitch = .off
            
            self.endLabel.textColor = .lightGray
            self.startLabel.textColor = .black
            
        }
        else {
            if self.calendar.isHidden {
                startSwitch = .on
                endSwitch = .off
                self.endLabel.textColor = .lightGray
                self.startLabel.textColor = .black
            }
            else {
                startSwitch = .off
                endSwitch = .off
                self.endLabel.textColor = .black
                self.startLabel.textColor = .black
                
            }
            self.calendar.isHidden = !self.calendar.isHidden
        }
    }
    
    @IBAction func didTapEndLabel(_ sender: UITapGestureRecognizer) {
        if startSwitch == .on {
            self.calendar.isHidden = false
            endSwitch = .on
            startSwitch = .off
            
            self.startLabel.textColor = .lightGray
            self.endLabel.textColor = .black
        }
        else {
            if self.calendar.isHidden {
                endSwitch = .on
                startSwitch = .off
                self.endLabel.textColor = .black
                self.startLabel.textColor = .lightGray
            }
            else {
                endSwitch = .off
                startSwitch = .off
                self.startLabel.textColor = .black
                self.endLabel.textColor = .black
            }
            self.calendar.isHidden = !self.calendar.isHidden
        }
    }
    
    // 무조건 써줘야 한다길래 써놓은 메소드
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        // Do other updates here
        calendar.frame = CGRect(origin: calendar.frame.origin, size: bounds.size)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if startSwitch == .on && endSwitch == .off {
            self.startLabel.text = date.toString()
        }
        else if startSwitch == .off && endSwitch == .on {
            self.endLabel.text = date.toString()
        }
        
        self.calendar.isHidden = true
        self.startLabel.textColor = .black
        self.endLabel.textColor = .black
        
    }
}
