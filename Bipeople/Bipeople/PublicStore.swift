//
//  PublicStore.swift
//  Bipeople
//
//  Created by 조준영 on 2017. 8. 14..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

enum StoreType : String, Codable {
    case downtown_parking   = "시내_보관대"
    case downtown_shop      = "시내_매장"
    case downtown_rental    = "시내_대여소"
    case downtown_toliet    = "시내_화장실"
    case downtown_bridge    = "시내_한강다리"
    case downtown_pump      = "시내_펌프"
    case hanriver_parking   = "한강_보관대"
    case hanriver_shop      = "한강_매점"
    case hanriver_rental    = "한강_대여소"
    case hanriver_drink     = "한강_식수대"
    case hanriver_stairs    = "한강_진출입_계단"
    case hanriver_bridge    = "한강_지천다리"
    case hanriver_elevator  = "한강_엘리베이터"
    case hanriver_access    = "한강_진출입로_경사"
    case none               = ""
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
    var CLASS : StoreType
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
        CLASS : StoreType,
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
