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
    case downtown_parking
    case downtown_store
    case downtown_rental
    case downtown_restroom
    case downtown_bridge
    case downtown_pump
    case hanriver_shelf
    case hanriver_store
    case hanriver_rental
    case hanriver_drink
    case hanriver_floor
    case hanriver_bridge
    case hanriver_elevator
    case hanriver_access    
    
    case none
}

enum ApiURL: String {
    case toiletURL = "http://openAPI.seoul.go.kr:8088/4944627561736d613130334c75587853/json/SearchPublicToiletPOIService/1/1000/"
    case wifiURL = "http://openapi.seoul.go.kr:8088/6464794f66736d613131377946497a4d/json/PublicWiFiPlaceInfo/1/1000"
    case storeURL = "http://openapi.seoul.go.kr:8088/4467715062736d61313031666a6d5867/json/GeoInfoBikeConvenientFacilitiesWGS/1/1000/"
}

class PublicPlace: Object {
    
    @objc dynamic var id : String = UUID().uuidString
    @objc dynamic var title = ""
    @objc dynamic var address = ""
    @objc dynamic var lat : Double = 0.0
    @objc dynamic var lng : Double = 0.0
    
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
    
    static func fetchList<T: Codable>( apiURL: ApiURL, _ type: T.Type,
                                       success: @escaping (T) -> Void,
                                       failure: @escaping (Error) -> Void) {
        
        guard let url = URL(string: apiURL.rawValue) else { return }
        
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
