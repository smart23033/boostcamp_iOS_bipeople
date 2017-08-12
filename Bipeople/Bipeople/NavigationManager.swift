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
    
    /// 싱글톤 패턴을 사용, 도착지 마커는 반드시 맵상에 1개만 존재해야 함
    private static let destinationMarker: GMSMarker = {
        
        let marker = GMSMarker()
        marker.icon = GMSMarker.markerImage(with: UIColor(red: 28/255.0, green: 176/255.0, blue: 184/255.0, alpha: 1.0))
        
        return marker
    }()
    
    /// 네비게이션 매니저가 사용할 맵뷰
    var mapMarkerShowed: GMSMapView?
    
    /// 싱글톤 패턴이 사용 된, 도착지 마커를 맵 위에 설정
    func setMarker(location: CLLocationCoordinate2D, name: String?, address: String?) throws {
        
        guard let map = mapMarkerShowed else {
            print("`mapMarkerShowed`을 먼저 설정해주세요")
            throw NSError()
        }
        
        NavigationManager.destinationMarker.position = location
        NavigationManager.destinationMarker.title = name ?? "Unknown"
        NavigationManager.destinationMarker.snippet = address ?? "Unknown"
        
        DispatchQueue.main.async {
            NavigationManager.destinationMarker.map = map
        }
    }
    
    /// TODO: T Map GeoJSON API를 통해 경로를 가져온다
    func getGeoJSONFromTMap() throws {
        
    }
}
