//
//  Geometry.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 12..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import Foundation

/// GeoJSON 표준 규격 형상 정보
class Geometry: Codable {
    
    enum Coordinates {
        case single([Double])
        case array([[Double]])
    }
    
    var type: String?                    /// Feature 도로 구간의 정보
    var coordinates: Coordinates?        /// 좌표 정보
    
    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let type = try? container.decode(String.self, forKey: .type) {
            self.type = type
        }
        
        if let coord = try? container.decode([Double].self, forKey: .coordinates) {
            self.coordinates = .single(coord)
        } else if let coords = try? container.decode([[Double]].self, forKey: .coordinates) {
            self.coordinates = .array(coords)
        }
        
        return
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.type, forKey: .type)
        
        switch coordinates {
        case let .single(coord)?:
            try container.encode(coord, forKey: .coordinates)
        case let .array(coords)?:
            try container.encode(coords, forKey: .coordinates)
        case .none:
            try container.encodeNil(forKey: .coordinates)
        }
    }
}
