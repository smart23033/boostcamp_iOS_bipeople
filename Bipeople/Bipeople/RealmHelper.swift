//
//  RealmHelper.swift
//  RealmHelper
//
//  Created by BLU on 2017. 8. 7..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import Foundation
import RealmSwift

class RealmHelper: NSObject {
    private static var realm: Realm {
        return try! Realm()
    }
    
    static func addData<T: Object>(data: T) {
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(data)
        }
    }
    
    static func fetchData<T: Object>(dataList: inout Array<T>) {
        let obj = realm.objects(T.self)
        for data in obj {
            dataList.append(data)
        }
    }
    
    static func removeData<T: Object>(data: T) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(data)
        }
    }
    
    static func removeAllData() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        
    }
    
    static func objectFromType<T: Object>(data: T) -> Results<T> {
        return realm.objects(T.self)
    }
    
    static func objectFromQuery<T: Object>(data: T, query: NSPredicate) -> T? {
        let realm = try! Realm()
        
        guard let object = realm.objects(T.self).filter("id = 1").first else { return nil }
        return object
    }
    
    static func updateObject<T: Object>(data: T, query: NSPredicate) {
        let realm = try! Realm()
        
        var object = realm.objects(T.self).filter("id = 1").first
        object = data
        try! realm.write {
            realm.add(object!, update: true)
        }
    }
    
//    static func updateData<T: Object>(data: T, query: NSPredicate) {
//        
//        try! realm.write {
//            realm.add(updateTask)
//        }
//    }
    
}
