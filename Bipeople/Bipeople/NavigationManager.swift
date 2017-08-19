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

struct Waypoint {
    
    var coord: CLLocationCoordinate2D
    var placeName: String
    var description: String
}

class NavigationManager {
    
    private static let TMAP_API_URL: String = "https://apis.skplanetx.com/tmap/routes/pedestrian"
    private static let VERSION: Int         = 1
    private static let FORMAT: String       = "json"
    private static let APP_KEY: String       = "5112af59-674c-38fd-89b0-ab54f1297284"
    
    private static let MINIMUM_RIDING_VELOCITY: Double      = 0.5   /// meters / seconds
    private static let RIDING_VELOCITY_THRESHOLD: Double    = 1000  /// meters / seconds
    
    private var mapViewForNavigation: GMSMapView
    
    private var navigationPath: GMSMutablePath?
    private var navigationRoute: GMSPolyline?
    
    private var routeWaypoints: [Waypoint] = []
    private var waypointsMarker: [GMSMarker] = []
    private var destinationMarker: GMSMarker?

    private var record: Record?
    private var traces: [Trace] = []
    
    /// 현재 위치가 도착지인지를 반환
    var isArrived: Bool {

        guard
            let destination = destinationMarker?.position,
            let currentLocation = mapViewForNavigation.myLocation
        else {
            return false
        }
        
        let arrivalLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        
        return currentLocation.distance(from: arrivalLocation) < 50
    }
    
    /// 현재 위치가 네비게이션 경로에서 벗어나 있는지를 반환
    var isAwayFromRoute: Bool {

        guard
            let currentCoord = mapViewForNavigation.myLocation?.coordinate,
            let navigationPath = navigationPath
        else {
            return false
        }
        
        return !GMSGeometryIsLocationOnPathTolerance(currentCoord, navigationPath, true, 50.0)
    }
    
    init(mapView: GMSMapView) {
        mapViewForNavigation = mapView  
    }
    
    /// 싱글톤 패턴이 사용 된, 도착지 마커를 맵 위에 설정
    func setDestination(at place: GMSPlace) {
        
        if destinationMarker == nil {
            let marker = GMSMarker()
            marker.icon = GMSMarker.markerImage(with: UIColor.primary)
            
            destinationMarker = marker
        }
        
        guard let marker = destinationMarker else {
            return
        }
        
        marker.map = nil     // Clear previous marker from map
        
        marker.position = place.coordinate
        marker.title = place.name
        marker.snippet = place.formattedAddress ?? LiteralString.unknown.rawValue
    }
    
    /// TODO: T Map GeoJSON API를 통해 경로를 가져온다
    func getGeoJSONFromTMap(failure: @escaping (Error) -> Void, success: @escaping (Data) throws -> Void) {
        
        guard
            let currentCoord = mapViewForNavigation.myLocation?.coordinate
        else {
            print("현재 위치를 아직 찾지 못했습니다")     // FOR DEBUG
            failure(TmapAPIError.invalidCurrentLocation)
            return
        }
        
        print("currentPosX: ", currentCoord.longitude)     // FOR DEBUG
        print("currentPosY: ", currentCoord.latitude)     // FOR DEBUG
        
        guard
            let destination = destinationMarker?.position
        else {
            print("먼저 도착지를 설정해 주세요")     // FOR DEBUG
            failure(TmapAPIError.invalidDestination)
            return
        }
        
        print("destinationX: ", destination.longitude)   // FOR DEBUG
        print("destinationY: ", destination.latitude)    // FOR DEBUG
        
        var urlString: String = NavigationManager.TMAP_API_URL
        let urlParams: [String:String] = [
            "version" : String(NavigationManager.VERSION),
            "format" : NavigationManager.FORMAT,
            "appKey" : NavigationManager.APP_KEY
        ]
        
        urlString.append(urlParams.reduce("?") { $0 + $1.0 + "=" + String(describing: $1.1) + "&" })
        print(urlString)            // FOR DEBUG
        
        let requestBody: [String:Any] = [
            "startX": currentCoord.longitude,  // 현재 위치 경도
            "startY": currentCoord.latitude,  // 현재 위치 위도
            "endX": destination.longitude,   // 목적지 경도
            "endY": destination.latitude,   // 목적지 위도
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
        Alamofire.request(urlString, method: .post, parameters: requestBody, encoding: URLEncoding.httpBody, headers: headers).responseJSON { response in

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
    
    /// T Map으로 부터 받아온 데이터로 부터 경로와 경유지를 추출
    func setRouteAndWaypoints(from data: GeoJSON) {
        
        routeWaypoints = []
        navigationPath = GMSMutablePath()
        guard let path = navigationPath else {
            return
        }
        
        print("GeoJSON data: ", data)   // FOR DEBUG
        data.features?.forEach {
            guard let coordinates = $0.geometry?.coordinates else {
                print($0.geometry?.type ?? "empty")     // FOR DEBUG
                return
            }
            
            if case let .single(coord) = coordinates {
                
                let coordinate = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                let placeName = $0.properties?.name ?? ""
                let description = $0.properties?.description ?? ""
                
                print(coordinate)    // FOR DEBUG
                path.add(coordinate)
                routeWaypoints.append(Waypoint(coord: coordinate, placeName: placeName , description: description))
            } else if case let .array(coords) = coordinates {
                coords.forEach { coord in
                    
                    let coordinate = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                    print(coordinate)    // FOR DEBUG
                    path.add(coordinate)
                }
            }
        }
    }
    
    /// T Map으로 부터 받아온 경로를 맵에 그림
    func drawRoute() {
        
        navigationRoute?.map = nil     // Clear previous route from map
        
        navigationRoute = GMSPolyline(path: navigationPath)
        navigationRoute?.strokeWidth = 5
        navigationRoute?.strokeColor = UIColor.primary
        
        DispatchQueue.main.async {
            self.navigationRoute?.map = self.mapViewForNavigation
        }
    }
    
    /// 경유지와 도착지에 마커를 맵에 뿌림
    func showMarkers() {
        
        // Clear previous marker from map
        for marker in waypointsMarker {
            marker.map = nil
        }
        
        waypointsMarker.removeAll()
        for waypoint in routeWaypoints {
            let marker = GMSMarker()
            
            marker.icon = GMSMarker.markerImage(with: UIColor.primary)
            marker.position = waypoint.coord
            marker.title = waypoint.placeName
            marker.snippet = waypoint.description
            
            waypointsMarker.append(marker)
        }
        
        DispatchQueue.main.async {
            self.destinationMarker?.map = self.mapViewForNavigation
            
            for marker in self.waypointsMarker {
                marker.map = self.mapViewForNavigation
            }
        }
    }
    
    func initDatas() throws {
        
        guard
            let currentLocation = mapViewForNavigation.myLocation?.coordinate,
            let destination = destinationMarker?.position
        else {
            record = nil
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "First, wait current location updated And set the destination"
                ]
            )
            
            throw error
        }
        
        let realm = try! Realm()
        realm.beginWrite()
        
        record = Record(flag: true)
        traces.removeAll()
        
        try! realm.commitWrite()
        
        GMSGeocoder().reverseGeocodeCoordinate(currentLocation) { response, error in
            
            guard error == nil else {
                print("Reverse Geocode from current coordinate failed with error: ", error!)    // FOR DEBUG
                return
            }
            
            guard let record = self.record else {
                print("Record is not ready")    // FOR DEBUG
                return
            }
            
            guard let address = response?.firstResult() else {
                print("Reverse Geocode result is empty")    // FOR DEBUG
                return
            }
            
            let realm = try! Realm()
            realm.beginWrite()
            
            record.departure = address.thoroughfare ?? ""
        
            try! realm.commitWrite()
        }
        
        GMSGeocoder().reverseGeocodeCoordinate(destination) { response, error in
            
            guard error == nil else {
                print("Reverse Geocode from current coordinate failed with error: ", error!)    // FOR DEBUG
                return
            }
            
            guard let record = self.record else {
                print("Record is not ready")    // FOR DEBUG
                return
            }
            
            guard let address = response?.firstResult() else {
                print("Reverse Geocode result is empty")    // FOR DEBUG
                return
            }
            
            let realm = try! Realm()
            realm.beginWrite()
            
            record.arrival = address.thoroughfare ?? ""
            
            try!realm.commitWrite()
        }
    }
    
    func addTrace(location: CLLocation, updatedTime: TimeInterval) throws {
        
        let realm = try! Realm()
        realm.beginWrite()
        
        guard let record = record else {
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Record must be initialized before addTrace"
                ]
            )
            
            realm.cancelWrite()
            throw error
        }
        
        if let last = traces.last {
            
            let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
            record.distance += location.distance(from: lastLocation)
            
            print("Speed: ", String(location.speed))
            switch location.speed {
                
                case _ where location.speed < 0: fallthrough
                case _ where location.speed > NavigationManager.MINIMUM_RIDING_VELOCITY:

                    print("Speed ​​measurement error due to low GPS reception rate")     // FOR DEBUG
                
            case _ where location.speed < NavigationManager.MINIMUM_RIDING_VELOCITY :
                
                record.restTime += updatedTime - last.timestamp
                print("Rest Time... \(record.restTime),")     // FOR DEBUG
                fallthrough
            default:
                record.maximumSpeed = max(record.maximumSpeed, location.speed)
            }
        }
        
        traces.append(Trace(recordID: record._id, coord : location.coordinate, timestamp: updatedTime))
        try! realm.commitWrite()
    }
    
    func saveData() throws {
        
        let realm = try! Realm()
        realm.beginWrite()
        
        guard let record = record else {
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Record must be initialized before addTrace"
                ]
            )
            
            realm.cancelWrite()
            throw error
        }
        
        guard traces.count > 0 else {
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Recording is possible only if at least one trace data exists"
                ]
            )
            
            realm.cancelWrite()
            throw error
        }
        
        if let firstTrace = traces.first, let lastTrace = traces.last {
            
            print("first: ", String(describing: firstTrace))
            print("last: ", String(describing: lastTrace))
            record.ridingTime = lastTrace.timestamp - firstTrace.timestamp
            
            let excerciseTime = record.ridingTime - record.restTime
            record.calories = excerciseTime * 0.139
            record.averageSpeed = excerciseTime > 0 ? record.distance / excerciseTime : 0
            
            record.distance /= 1000.0
        }
        
        try! realm.commitWrite()

        RealmHelper.add(data: record)
        RealmHelper.add(datas: traces)
    }
}

