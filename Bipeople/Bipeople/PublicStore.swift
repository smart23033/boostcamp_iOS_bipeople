//
//  PublicStore.swift
//  Bipeople
//
//  Created by 조준영 on 2017. 8. 14..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

enum StoreType : String {
    case downtown_shelf = "시내_보관대"
    case downtown_store = "시내_매장"
    case downtown_rental = "시내_대여소"
    case downtown_restroom = "시내_화장실"
    case hanriver_shelf = "한강_보관대"
    case hanriver_store = "한강_매점"
}

struct PublicStore: Codable {
    var geoInfoBikeConvenientFacilitiesWGS : GeoInfoBikeConvenientFacilitiesWGS
    private enum CodingKeys : String, CodingKey {
        case geoInfoBikeConvenientFacilitiesWGS = "GeoInfoBikeConvenientFacilitiesWGS"
    }
    init(geoInfoBikeConvenientFacilitiesWGS: GeoInfoBikeConvenientFacilitiesWGS) {
        self.geoInfoBikeConvenientFacilitiesWGS = geoInfoBikeConvenientFacilitiesWGS
    }
}

struct GeoInfoBikeConvenientFacilitiesWGS : Codable {
    var listTotalCount : Int
    var result : [String : String]
    var row : [Store]
    
    private enum CodingKeys : String, CodingKey {
        case listTotalCount = "list_total_count"
        case result = "RESULT"
        case row = "row"
    }
    
    init(
        listTotalCount: Int,
        result: [String : String],
        row:[Store]
        ) {
        self.listTotalCount = listTotalCount
        self.result = result
        self.row = row
    }
}

struct Store : Codable {
    var OBJECTID : Int
    var FILENAME : String
    var CLASS : String
    var ADDRESS : String
    var LNG : String
    var LAT : String
    
    private enum CodingKeys : String, CodingKey {
        case OBJECTID = "OBJECTID"
        case FILENAME = "FILENAME"
        case CLASS = "CLASS"
        case ADDRESS = "ADDRESS"
        case LNG = "LNG"
        case LAT = "LAT"
    }
    
    init(
        OBJECTID : Int,
        FILENAME : String,
        CLASS : String,
        ADDRESS : String,
        LNG : String,
        LAT : String
        ) {
        self.OBJECTID = OBJECTID
        self.FILENAME = FILENAME
        self.CLASS = CLASS
        self.ADDRESS = ADDRESS
        self.LNG = LNG
        self.LAT = LAT
    }
}
