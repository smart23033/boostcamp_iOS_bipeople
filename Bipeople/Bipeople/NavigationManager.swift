//
//  NavigationManager.swift
//  Bipeople
//
//  Created by CONNECT on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import Foundation
import GoogleMaps
import Alamofire

enum TmapAPIError: Error {
    case invalidJSONData
    case invalidRequest
    case invalidResponse
    case unknown
}

class NavigationManager {
    
    private static let TMAP_API_URL: String = "https://apis.skplanetx.com/tmap/routes/pedestrian"
    private static let version: Int         = 1
    private static let format: String       = "json"
    private static let appKey: String       = "5112af59-674c-38fd-89b0-ab54f1297284"
    
    /// 싱글톤 패턴을 사용, 도착지 마커는 반드시 맵상에 1개만 존재해야 함
    private static var singletoneMarker: GMSMarker? = nil
    
    private var destinationMarker: GMSMarker? {
        
        return NavigationManager.singletoneMarker
    }
    
    /// 네비게이션 매니저가 사용할 맵뷰
    var mapMarkerShowed: GMSMapView?
    
    /// 싱글톤 패턴이 사용 된, 도착지 마커를 맵 위에 설정
    func setMarker(location: CLLocationCoordinate2D, name: String?, address: String?) throws {
        
        guard let map = mapMarkerShowed else {
            print("`mapMarkerShowed`을 먼저 설정해주세요")
            throw NSError()
        }
        
        if destinationMarker == nil {
            NavigationManager.singletoneMarker = GMSMarker()
            NavigationManager.singletoneMarker?.icon = GMSMarker.markerImage(with: UIColor.primaryColor)
        }
        
        destinationMarker?.position = location
        destinationMarker?.title = name ?? "Unknown"
        destinationMarker?.snippet = address ?? "Unknown"
        
        DispatchQueue.main.async {
            self.destinationMarker?.map = map
        }
    }
    
    /// TODO: T Map GeoJSON API를 통해 경로를 가져온다
    func getGeoJSONFromTMap(failure: @escaping (Error) -> Void, success: @escaping (Data) throws -> Void) {
        
        guard
            let currentPosX = mapMarkerShowed?.myLocation?.coordinate.longitude,
            let currentPosY = mapMarkerShowed?.myLocation?.coordinate.latitude
        else {
            print("현재 위치를 아직 찾지 못했습니다")
            return
        }
        
        guard
            let destinationX = destinationMarker?.position.longitude,
            let destinationY = destinationMarker?.position.latitude
        else {
            print("도착지를 먼저 설정해주세요")
            return
        }
        
        print("currentPosX: ", currentPosX)
        print("currentPosY: ", currentPosY)
        print("destinationX: ", destinationX)
        print("destinationY: ", destinationY)
        
        var urlString: String = NavigationManager.TMAP_API_URL
        let urlParams: [String:String] = [
            "version" : String(NavigationManager.version),
            "format" : NavigationManager.format,
            "appKey" : NavigationManager.appKey
        ]
        
        urlString.append(urlParams.reduce("?") { $0 + $1.0 + "=" + String(describing: $1.1) + "&" })
        print(urlString)
        
        let requestBody: [String:Any] = [
            "startX": currentPosX,
            "startY": currentPosY,
            "endX": destinationX,
            "endY": destinationY,
            "reqCoordType": "WGS84GEO",
            "startName": "출발",
            "endName": "도착",
            "resCoordType": "WGS84GEO"
        ]
        
        let headers: [String:String] = [
            "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
            "Accept": "application/json",
            "Accept-Language": "ko"
        ]
        
        Alamofire.request(urlString, method: .post, parameters: requestBody, encoding: URLEncoding.httpBody, headers: headers)
            .responseJSON { response in

                guard let data = response.data else {
                    failure(TmapAPIError.invalidResponse)
                    return
                }

                do {
                    try success(data)
                } catch {
                    failure(error)
                }
        }
    }
}

