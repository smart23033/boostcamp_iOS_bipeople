//
//  Track.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

//    데이터포멧 2
//    Pk
//    위도
//    경도
//    타임스탬프

import RealmSwift
import CoreLocation

class Trace: Object {
    
    @objc dynamic var recordID: Int = 0
    @objc dynamic var latitude: CLLocationDegrees = 0.0
    @objc dynamic var longitude: CLLocationDegrees = 0.0
    @objc dynamic var timestamp: TimeInterval = 0.0
    
    convenience init(recordID: Int, coord: CLLocationCoordinate2D, timestamp: TimeInterval) {
        self.init()
        
        self.recordID = recordID
        self.latitude = coord.latitude
        self.longitude = coord.longitude
        self.timestamp = timestamp
    }
}
