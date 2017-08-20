//
//  Feature.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 12..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import Foundation

/// GeoJSON 표준 규격 Point / Line 형상 정보
class Feature: Codable {
    
    var type: String?           /// 안내점, 출발점, 도착점, 경유지 정보
    var geometry: Geometry?     /// 형상 정보
    var properties: Properties? /// 사용자 정의 프로퍼티 정보
}
