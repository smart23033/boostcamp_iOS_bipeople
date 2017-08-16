//
//  swift
//  Bipeople
//
//  Created by CONNECT on 2017. 8. 10..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces
import Alamofire
import RealmSwift

enum TmapAPIError: Error {
    case invalidCurrentLocation
    case invalidDestination
    case invalidJSONData
    case invalidRequest
    case invalidResponse
    case unknown
}

class NavigationManager {
    
    private static let TMAP_API_URL: String = "https://apis.skplanetx.com/tmap/routes/pedestrian"
    private static let VERSION: Int         = 1
    private static let FORMAT: String       = "json"
    private static let APP_KEY: String       = "5112af59-674c-38fd-89b0-ab54f1297284"
    
    private static let MINIMUM_RIDING_VELOCITY: Double      = 1.5   /// meters / seconds
    private static let RIDING_VELOCITY_THRESHOLD: Double    = 14   /// meters / seconds
    
    private var mapViewForNavigation: GMSMapView
    
    private var destinationMarker: GMSMarker?
    private var navigationRoute: GMSPolyline?

    private var record: Record?
    private var traces: [Trace] = []
    
    init(mapView: GMSMapView) {
        mapViewForNavigation = mapView  
    }
    
    /// 싱글톤 패턴이 사용 된, 도착지 마커를 맵 위에 설정
    func setMarker(place: GMSPlace) {
        
        if destinationMarker == nil {
            destinationMarker = GMSMarker()
            destinationMarker?.icon = GMSMarker.markerImage(with: UIColor.primary)
        }
        
        mapViewForNavigation.clear()
        
        guard let marker = destinationMarker else {
            return
        }
        
        marker.position = place.coordinate
        marker.title = place.name
        marker.snippet = place.formattedAddress ?? "Unknown"
        
        DispatchQueue.main.async {
            marker.map = self.mapViewForNavigation
        }
    }
    
    /// TODO: T Map GeoJSON API를 통해 경로를 가져온다
    func getGeoJSONFromTMap(toward place: GMSPlace, failure: @escaping (Error) -> Void, success: @escaping (Data) throws -> Void) {
        
        guard
            let currentPosX = mapViewForNavigation.myLocation?.coordinate.longitude,
            let currentPosY = mapViewForNavigation.myLocation?.coordinate.latitude
        else {
            print("현재 위치를 아직 찾지 못했습니다")
            failure(TmapAPIError.invalidCurrentLocation)
            return
        }
        
        print("currentPosX: ", currentPosX)     // FOR DEBUG
        print("currentPosY: ", currentPosY)     // FOR DEBUG
        
        let destinationX = place.coordinate.longitude
        let destinationY = place.coordinate.latitude
        
        print("destinationX: ", destinationX)   // FOR DEBUG
        print("destinationY: ", destinationY)   // FOR DEBUG
        
        var urlString: String = NavigationManager.TMAP_API_URL
        let urlParams: [String:String] = [
            "version" : String(NavigationManager.VERSION),
            "format" : NavigationManager.FORMAT,
            "appKey" : NavigationManager.APP_KEY
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
        
        navigationRoute = GMSPolyline(path: navigationPath)
        
        guard let route = navigationRoute else {
            return
        }
        
        route.strokeWidth = 5
        route.strokeColor = UIColor.primary
        
        DispatchQueue.main.async {
            route.map = self.mapViewForNavigation
        }
    }
    
    func initDatas(departure: String, arrival: String) {
        
        traces.removeAll()
        record = Record(departure: departure, arrival: arrival)
    }
    
    func addTrace(location: CLLocation, updatedTime: TimeInterval) throws {
        
        guard let record = record else {
            
            let error = NSError(
                domain: "kr.or.connect.boostcamp",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "record must be initialized before addTrace"
                ]
            )
            
            throw error
        }
        
        if let last = traces.last {
            
            record.distance += location.distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
            
            switch location.speed {
                
                case _ where location.speed < NavigationManager.MINIMUM_RIDING_VELOCITY :
                    
                    print("Rest Time...")
                    record.restTime += updatedTime - last.timestamp
                
                case _ where location.speed > NavigationManager.MINIMUM_RIDING_VELOCITY :
                    
                    print("Speed ​​measurement error due to low GPS reception rate")
                
                default:
                    
                    record.maximumSpeed = max(record.maximumSpeed, location.speed)
            }
        }
        
        traces.append(Trace(recordID: record._id, coord : location.coordinate, timestamp: updatedTime))
    }
    
    func saveData() throws {
        
        guard let record = record else {
            
            let error = NSError(
                domain: "kr.or.connect.boostcamp",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "record must be initialized before addTrace"
                ]
            )
            
            throw error
        }
        
        guard traces.count > 0 else {
            
            let error = NSError(
                domain: "kr.or.connect.boostcamp",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Recording is possible only if at least one trace data exists"
                ]
            )
            
            throw error
        }
        
        if let firstTrace = traces.first, let lastTrace = traces.last {
            
            record.ridingTime = lastTrace.timestamp - firstTrace.timestamp
            
            let excerciseTime = record.ridingTime - record.restTime
            record.calories = excerciseTime * 0.139
            record.averageSpeed = record.distance / excerciseTime
        }
        
        RealmHelper.add(data: record)
    }
}

