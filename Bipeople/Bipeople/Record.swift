//
//  Record.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 10..
//  Copyright © 2017년 BluePotato. All rights reserved.
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


// MARK: Enum

enum LiteralString: String {
    case apptitle   = "Bipeople"
    case tracking   = "위치 검색 중"
    case unknown    = "미확인 장소"
}


// MARK: Class

class Record: Object {
    
    @objc dynamic var _id: Int = 0
    @objc dynamic var departure: String = LiteralString.unknown.rawValue
    @objc dynamic var arrival: String = LiteralString.unknown.rawValue
    @objc dynamic var distance: Double = 0.0
    @objc dynamic var ridingTime: TimeInterval = 0.0
    @objc dynamic var restTime: TimeInterval = 0.0
    @objc dynamic var averageSpeed: Double = 0.0
    @objc dynamic var maximumSpeed: Double = 0.0
    @objc dynamic var calories: Double = 0.0
    @objc dynamic var createdAt: Date = Date()
    
    convenience init(flag: Bool = true) {
        self.init()
        
        self._id = flag ? Record.autoIncrement() : 0
    }
    
    convenience init(departure: String, arrival: String, distance: Double, ridingTime: TimeInterval, restTime: TimeInterval, averageSpeed: Double, maximumSpeed: Double, calories: Double) {
        
        self.init()
        
        self._id = Record.autoIncrement()
        self.departure = departure
        self.arrival = arrival
        self.distance = distance
        self.ridingTime = ridingTime
        self.restTime = restTime
        self.averageSpeed = averageSpeed
        self.maximumSpeed = maximumSpeed
        self.calories = calories
        self.createdAt = generateRandomDate(daysBack: 50)
    }
    
    override class func primaryKey() -> String? {
        return "_id"
    }
    
    /// Return Maximum(_id) + 1
    class func autoIncrement() -> Int {
        
        let realm = try! Realm()
        if let retNext = realm.objects(Record.self).sorted(byKeyPath: "_id").last?._id {
            return retNext + 1
        } else {
            return 0
        }
    }
    
    /// 랜덤날짜 생성
    func generateRandomDate(daysBack: Int)-> Date {
        let day = arc4random_uniform(UInt32(daysBack)+1)
        let hour = arc4random_uniform(23)
        let minute = arc4random_uniform(59)
        
        let today = Date()
        let gregorian  = Calendar(identifier: Calendar.Identifier.gregorian)
        var offsetComponents = DateComponents()
        offsetComponents.day = Int(day)
        offsetComponents.hour = Int(hour)
        offsetComponents.minute = Int(minute)
        
        let randomDate = gregorian.date(byAdding: offsetComponents, to: today)
        
        return randomDate ?? Date()
    }
    
}
