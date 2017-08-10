//
//  NavigationManager.swift
//  Bipeople
//
//  Created by CONNECT on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import Foundation
import GoogleMaps

class NavigationManager {
    
    private static let destinationMarker: GMSMarker = .init()
    
    var mapMarkerShowed: GMSMapView?
    
    func setMarker(location: CLLocationCoordinate2D, name: String?, address: String?) -> Bool {
        
        guard let map = mapMarkerShowed else {
            print("`mapMarkerShowed`을 먼저 설정해주세요")
            return false
        }
        
        NavigationManager.destinationMarker.position = location
        NavigationManager.destinationMarker.title = name ?? "Unknown"
        NavigationManager.destinationMarker.snippet = address ?? "Unknown"
        
        DispatchQueue.main.async {
            NavigationManager.destinationMarker.map = map
        }
        
        return true
    }
}
