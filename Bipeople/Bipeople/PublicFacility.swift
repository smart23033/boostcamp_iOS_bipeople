//
//  PublicFacility.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 14..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit

enum FacilityType : String {
    case downtown_shelf = "시내_보관대"
    case downtown_store = "시내_매장"
    case downtown_rental = "시내_대여소"
    case downtown_restroom = "시내_화장실"
    case hanriver_shelf = "한강_보관대"
    case hanriver_store = "한강_매점"
}

struct PublicFacility: Codable {
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
    var row : [Facility]
    
    private enum CodingKeys : String, CodingKey {
        case listTotalCount = "list_total_count"
        case result = "RESULT"
        case row = "row"
    }
    
    init(
        listTotalCount: Int,
        result: [String : String],
        row:[Facility]
        ) {
        self.listTotalCount = listTotalCount
        self.result = result
        self.row = row
    }
}

struct Facility : Codable {
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
