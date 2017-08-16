//
//  Extensions.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import CoreLocation

/// MARK: Date Extension
extension Date {
    
    /// date to string
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        // dateFormatter.timeZone   = TimeZone(abbreviation: "GMT")
        
        return dateFormatter.string(from: self)
    }
    
    func isInSameWeek(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }
    
    func isInSameMonth(date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }
    
    func isInSameDay(date: Date) -> Bool {
        
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
    
    func generateDates(startDate :Date?, endDate: Date?, addbyUnit:Calendar.Component) -> [Date]
    {
        let calendar = Calendar.current
        var datesArray: [Date] =  [Date]()
        var newDate = startDate
        
        while true {
            if newDate?.isInSameDay(date: endDate!) == true {
                break
            }
            
            newDate = calendar.date(byAdding: addbyUnit, value: 1, to: newDate!)!
            datesArray.append(newDate!)
            
        }
        
        return datesArray
    }
    
}

/// MARK: String Extension
extension String {
    
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone   = TimeZone(abbreviation: "GMT")
        guard let date = dateFormatter.date(from: self) else {
            return nil
        }
        
        return date
    }
    
}

/// MARK: Double Extension
extension Double {
    
    /// 소수점 x 자릿수부터 반올림
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

/// MARK: UIColor Extension
extension UIColor {
    static let primary = UIColor(hex: 0x1cb0b8)
    
    /// Create a UIColor from RGB
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    /// Create a UIColor from a hex value (E.g 0x000000)
    convenience init(hex: Int, a: CGFloat = 1.0) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF,
            a: a
        )
    }
}
