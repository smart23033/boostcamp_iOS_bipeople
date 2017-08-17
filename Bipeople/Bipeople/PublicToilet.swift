//
//  PublicResponse.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 9..
//  Copyright © 2017년 futr_blu. All rights reserved.
//


struct PublicToilet: Codable {
    
    var searchPublicToiletPOIService : ToiletResponse
    private enum CodingKeys : String, CodingKey {
        case searchPublicToiletPOIService = "SearchPublicToiletPOIService"
    }
    init(searchPublicToiletPOIService: ToiletResponse) {
        self.searchPublicToiletPOIService = searchPublicToiletPOIService
    }
}
struct ToiletResponse: Codable {
    var listTotalCount : Int
    var result : [String : String]
    //[CODE: String, MESSAGE: String)?
    var row : [Toilet]
    
    private enum CodingKeys : String, CodingKey {
        case listTotalCount = "list_total_count"
        case result = "RESULT"
        case row = "row"
    }
    
    init(
        listTotalCount: Int,
        result: [String : String],
        row:[Toilet]
        ) {
        self.listTotalCount = listTotalCount
        self.result = result
        self.row = row
    }
}

class Toilet: Codable {
    var poi_ID : String
    var fName : String
    var aName : String
    var cName : String
    var center_x1 : Double
    var center_y1 : Double
    var x_Wgs84 : Double
    var y_Wgs84 : Double
    var insertDate : String
    var updateDate : String
    
    private enum CodingKeys : String, CodingKey {
        case poi_ID = "POI_ID"
        case fName = "FNAME"
        case aName = "ANAME"
        case cName = "CNAME"
        case center_x1 = "CENTER_X1"
        case center_y1 = "CENTER_Y1"
        case x_Wgs84 = "X_WGS84"
        case y_Wgs84 = "Y_WGS84"
        case insertDate = "INSERTDATE"
        case updateDate = "UPDATEDATE"
    }
    
    init(
        poi_ID: String,
        fName: String,
        aName: String,
        cName: String,
        center_x1: Double,
        center_y1: Double,
        x_Wgs84: Double,
        y_Wgs84: Double,
        insertDate: String,
        updateDate: String
        ) {
        self.poi_ID = poi_ID
        self.fName = fName
        self.aName = aName
        self.cName = cName
        self.center_x1 = center_x1
        self.center_y1 = center_y1
        self.x_Wgs84 = x_Wgs84
        self.y_Wgs84 = y_Wgs84
        self.insertDate = insertDate
        self.updateDate = updateDate
    }
}
