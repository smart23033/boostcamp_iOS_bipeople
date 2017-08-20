//
//  PublicPlace.swift
//  Bipeople
//
//  Created by 조준영 on 2017. 8. 14..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import RealmSwift
import Alamofire

enum PlaceType: String {
    case toilet
	case wifi
    case store
    case none
}

class PublicPlace: Object {
    
    @objc dynamic var id : String = UUID().uuidString
    @objc dynamic var location = ""
    @objc dynamic var lat : Double = 0.0
    @objc dynamic var lng : Double = 0.0
    @objc dynamic var imageURL : String = ""
    
    @objc private dynamic var _placeType: String = ""
    public var placeType: PlaceType {
        get { return PlaceType(rawValue: self._placeType) ?? .none }
        set { self._placeType = newValue.rawValue }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override class func ignoredProperties() -> [String] {
        return ["placeType"]
    }
    
    static func fetchList<T: Codable>( url:String, _ type: T.Type,
                                       success: @escaping (T) -> Void,
                                       failure: @escaping (Error) -> Void) {
        
        guard let url = URL(string: url) else { return }
        
        Alamofire.request(url).responseJSON { response in
            
            guard let data = response.data else {
                
                failure(NSError())
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                success(decoded)
            } catch {
                failure(error)
            }
        }
    }
}
