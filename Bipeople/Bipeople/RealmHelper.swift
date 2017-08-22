//
//  RealmHelper.swift
//  RealmHelper
//
//  Created by 조준영 on 2017. 8. 7..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import RealmSwift

public class RealmHelper: NSObject {
    
    private static var realm: Realm {
        return try! Realm()
    }
    
    class func add<T: Object>(data: T) {
        
        try! realm.write {
            realm.add(data)
        }
    }
    
    class func add<T: Object>(datas: Array<T>) {
        
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(datas)
        }
    }
    
    class func fetch<T: Object>(from: T.Type) -> Results<T> {
        let results = realm.objects(T.self)
        
        return results
    }
    
    class func fetch<T: Object>(from: T.Type, with predicate: NSPredicate) -> Results<T> {
        let results = realm.objects(T.self).filter(predicate)
        
        return results
    }
    
    class func delete<T: Object>(data: T) {
        
        try! realm.write {
            realm.delete(data)
        }
    }
    
    class func deleteAll() {
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    class func deleteTable<T: Object>(of type: T.Type) {
        
        try! realm.write {
            realm.delete(fetch(from: T.self))
        }
    }
    
}
