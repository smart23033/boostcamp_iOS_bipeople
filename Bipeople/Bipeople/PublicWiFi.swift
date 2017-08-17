//
//  WifiResponse.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 14..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit

struct PublicWiFi : Codable {

    var publicWiFiPlaceInfo : PublicWiFiPlaceInfo
    private enum CodingKeys : String, CodingKey {
        case publicWiFiPlaceInfo = "PublicWiFiPlaceInfo"
    }
    init(publicWiFiPlaceInfo: PublicWiFiPlaceInfo) {
        self.publicWiFiPlaceInfo = publicWiFiPlaceInfo
    }
    
}

struct PublicWiFiPlaceInfo : Codable {
    var listTotalCount : Int
    var result : [String : String]
    var row : [WiFi]
    
    private enum CodingKeys : String, CodingKey {
        case listTotalCount = "list_total_count"
        case result = "RESULT"
        case row = "row"
    }
    
    init(
        listTotalCount: Int,
        result: [String : String],
        row:[WiFi]
        ) {
        self.listTotalCount = listTotalCount
        self.result = result
        self.row = row
    }
}


struct WiFi : Codable {
    var GU_NM : String
    var CATEGORY : String
    var PLACE_NAME : String
    var INSTL_X : Double
    var INSTL_Y : Double
    var INSTL_DIV : String
    
    init(
        GU_NM: String,
        CATEGORY: String,
        PLACE_NAME: String,
        INSTL_X: Double,
        INSTL_Y: Double,
        INSTL_DIV: String
        ) {
        self.GU_NM = GU_NM
        self.CATEGORY = CATEGORY
        self.PLACE_NAME = PLACE_NAME
        self.INSTL_X = INSTL_X
        self.INSTL_Y = INSTL_Y
        self.INSTL_DIV = INSTL_DIV
    }
}
