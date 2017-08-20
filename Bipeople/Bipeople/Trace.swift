//
//  Trace.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 10..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

//    데이터포멧 2
//    Pk
//    위도
//    경도
//    타임스탬프

import RealmSwift
import CoreLocation

class Trace: Object {
    
    @objc dynamic var recordID: Int = -1
    @objc dynamic var latitude: CLLocationDegrees = -1
    @objc dynamic var longitude: CLLocationDegrees = -1
    @objc dynamic var altitude: CLLocationDegrees = -1
    @objc dynamic var speed: CLLocationDegrees = -1
    @objc dynamic var timestamp: Date = Date()
    
    convenience init(recordID: Int, location: CLLocation) {
        self.init()
        
        self.recordID   = recordID
        self.latitude   = location.coordinate.latitude
        self.longitude  = location.coordinate.longitude
        self.altitude   = location.altitude
        self.speed      = location.speed
        self.timestamp  = location.timestamp
    }
}
