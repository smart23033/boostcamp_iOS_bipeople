//
//  Track.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

//    Pk
//    위도
//    경도
//    타임스탬프

import Foundation

class Track: Codable {
    

    var _id: Int
    var latitude: Double
    var longitude: Double
    var createdAt: TimeInterval
}
