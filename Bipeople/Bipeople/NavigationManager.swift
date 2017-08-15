//
//  swift
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
    
    private var mapViewForNavigation: GMSMapView?
    private var destinationMarker: GMSMarker?
    private var navigationRoute: GMSPolyline?
    
    private var traces: [Trace] = []
    
    func setMapView(view: GMSMapView) {
        mapViewForNavigation = view
    }
    
    /// 싱글톤 패턴이 사용 된, 도착지 마커를 맵 위에 설정
    func setMarker(location: CLLocationCoordinate2D, name: String?, address: String?) throws {
        
        guard let map = mapViewForNavigation else {
            print("`mapUsedForNavigation`을 먼저 설정해주세요")
            throw NSError()
        }
        
        if destinationMarker == nil {
            destinationMarker = GMSMarker()
            destinationMarker?.icon = GMSMarker.markerImage(with: UIColor.primary)
        }
        
        destinationMarker?.position = location
        destinationMarker?.title = name ?? "Unknown"
        destinationMarker?.snippet = address ?? "Unknown"
        
        DispatchQueue.main.async {
            self.destinationMarker?.map = map
        }
    }
    
    func removeMarker() {
        
        destinationMarker?.map = nil
    }
    
    func eraseRoute() {
        
        navigationRoute?.map = nil
    }
    
    /// TODO: T Map GeoJSON API를 통해 경로를 가져온다
    func getGeoJSONFromTMap(failure: @escaping (Error) -> Void, success: @escaping (Data) throws -> Void) {
        
        guard
            let currentPosX = mapViewForNavigation?.myLocation?.coordinate.longitude,
            let currentPosY = mapViewForNavigation?.myLocation?.coordinate.latitude
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
            "startX": currentPosX,  // 현재 위치 경도
            "startY": currentPosY,  // 현재 위치 위도
            "endX": destinationX,   // 목적지 경도
            "endY": destinationY,   // 목적지 위도
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
        
        // T Map에 현재 위치와, 목적지 경도/위도를 전달하여 경로를 요청
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
    
    func drawRoute(from data: GeoJSON) {
        let navigationPath = GMSMutablePath()
        
        print("GeoJSON data: ", data)
        data.features?.forEach {
            guard let coordinates = $0.geometry?.coordinates else {
                print($0.geometry?.type ?? "empty")
                return
            }
            
            if case let .single(coord) = coordinates {
                
                print(coord)    // FOR DEBUG
                navigationPath.add(CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]))
            } else if case let .array(coords) = coordinates {
                coords.forEach { coord in
                    
                    print(coord)    // FOR DEBUG
                    navigationPath.add(CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]))
                }
            }
        }
        mapViewForNavigation?.clear()
        
        navigationRoute = GMSPolyline(path: navigationPath)
        navigationRoute?.strokeWidth = 5
        navigationRoute?.strokeColor = UIColor.primary
        navigationRoute?.map = mapViewForNavigation
    }
    
    func addTrace(coord: CLLocationCoordinate2D) {
        
        traces.append(Trace(coordinate: coord))
    }
    
    func clearTraces() {
        
        traces.removeAll()
    }
    
    func saveRecord() {
        
        // Record 생성
        // traces.forEach {
        //    $0.recordID = record._id
        //    RealmHelper.addData
        //}
    }
}

