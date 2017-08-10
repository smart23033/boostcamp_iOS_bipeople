//
//  ToiletResponse.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit

class ToiletResponse: Codable {
    var listTotalCount : Int?
    var result : [String : String]?
    //[CODE: String, MESSAGE: String)?
    var row : [Toilet]?
    
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

