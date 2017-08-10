//
//  PublicResponse.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 9..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import CodableAlamofire

struct PublicResponse: Decodable {
    
//    enum DataType: String, Codable {
//        case wifi = "wifi"
//        case toilet = "toilet"
//        case facility = "facility"
//    }
//    var service: DataType?
    //var serviceModel : AnyClass?

//    init?(service: DataType) {
//        self.service = service
//        switch service {
//        case .wifi:
//            self.serviceModel = PlaceListVC
//        case .toilet:
//            self.serviceModel = PlaceListVC
//        case .facility:
//            self.serviceModel = PlaceListVC
//        }
        //self.serviceModel =
//    }
    
    var searchPublicToiletPOIService : ToiletResponse
    private enum CodingKeys : String, CodingKey {
        case searchPublicToiletPOIService = "SearchPublicToiletPOIService"
    }
//    init(searchPublicToiletPOIService: ToiletResponse) {
//        self.searchPublicToiletPOIService = searchPublicToiletPOIService
//    }
}

//extension PublicResponse: Equatable {
//    public static func ==(lhs: PublicResponse, rhs: PublicResponse) -> Bool {
//        return lhs.service == rhs.service
//    }
//}

