//
//  ToiletResponse.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import CodableAlamofire

struct ToiletResponse: Decodable {
    var listTotalCount : String
    var result : String
    var row : [Toilet]
    
    private enum CodingKeys : String, CodingKey {
        case listTotalCount = "list_total_count"
        case result = "RESULT"
        case row = "row"
    }
    
//    init(
//        listTotalCount: String,
//        result: String,
//        row:[Toilet]
//        ) {
//        self.listTotalCount = listTotalCount
//        self.result = result
//        self.row = row
//    }
}
