//
//  Record.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

//    데이터 포멧 1
//    Pk
//    출발지명
//    도착지명
//    주행거리
//    주행시간
//    휴식시간
//    평균속도
//    최고속도
//    소모칼로리
//    저장날짜

import RealmSwift

class Record: Object {
    @objc dynamic var _id: Int = 0
    @objc dynamic var departure: String = ""
    @objc dynamic var arrival: String = ""
    @objc dynamic var distance: Double = 0.0
    @objc dynamic var ridingTime: TimeInterval = 0.0
    @objc dynamic var restTime: TimeInterval = 0.0
    @objc dynamic var averageSpeed: Double = 0.0
    @objc dynamic var highestSpeed: Double = 0.0
    @objc dynamic var calories: Double = 0.0
    @objc dynamic var createdAt: Date = Date()
    
    //Incrementa ID
    static func autoIncrement() -> Int {
        let realm = try! Realm()
        if let retNext = realm.objects(Record.self).sorted(byKeyPath: "_id").first?._id {
            return retNext + 1
        }else{
            return 1
        }
    }
}
