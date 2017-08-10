//
//  Record.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

//Pk
//출발지명
//도착지명
//주행거리
//주행시간
//휴식시간
//평균속도
//최고속도
//소모칼로리
//저장날짜

import Foundation

class Record: Codable {

    var _id: Int
    var departure: String
    var arrival: String
    var distance: Double
    var ridingTime: TimeInterval
    var restTime: TimeInterval
    var averageSpeed: Double
    var highestSpeed: Double
    var calories: Double
    var createdAt: Date
    
}
