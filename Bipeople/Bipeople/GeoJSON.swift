//
//  GeoJSON.swift
//  Bipeople
//
//  Created by CONNECT on 2017. 8. 12..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import Foundation

/// T Map API 보행자 경로안내 Response JSON Format
class GeoJSON: Codable {
    
    var type: String?           /// GeoJSON 표준 프로퍼티
    var features: [Feature]?    /// Point, Line 형상 정보
}
