//
//  Place.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 14..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import RealmSwift

enum PlaceType: String {
    case toilet
	case wifi
    case store
    case none
}

class Place: Object {
    @objc dynamic var id : String = UUID().uuidString
    @objc dynamic var location = ""
    @objc dynamic var lat : Double = 0.0
    @objc dynamic var lng : Double = 0.0
    @objc dynamic var imageURL : String = ""
    
    var placeType: PlaceType {
        get { return PlaceType(rawValue: self._placeType) ?? .none }
        set { self._placeType = newValue.rawValue }
    }
    
    @objc private dynamic var _placeType: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override class func ignoredProperties() -> [String] {
        return ["placeType"]
    }
}
