//
//  NavigationManager.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 10..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces
import Alamofire
import RealmSwift
import AVFoundation



// MARK: Enum

/// T Map API 사용 중 발생 가능한 에러
enum TmapAPIError: Error {
    case invalidCurrentLocation
    case invalidDestination
    case invalidJSONData
    case invalidRequest
    case invalidResponse
    case unknown
}

/// 네비게이션 작동 중 가능한 상태
enum NavigationStatus {
    case arrived        // 도착
    case waypoint(Int)  // 중간경유
    case offroad        // 경로이탈
    case onroad         // 정상주행
    case freeride       // 자유주행
    case error          // 에러
}



// MARK: Struct

/// 경유지 구조체
struct Waypoint {
    
    var coord: CLLocationCoordinate2D   // 위치
    var placeName: String               // 지명
    var description: String             // 음성 안내 문구
}



// MARK: Class

class NavigationManager {
    
    // MARK: Static Private Variables
    
    static private let TMAP_API_URL: String = "https://apis.skplanetx.com/tmap/routes/pedestrian"
    static private let VERSION: Int         = 1
    static private let FORMAT: String       = "json"
    static private let APP_KEY: String       = "5112af59-674c-38fd-89b0-ab54f1297284"
    static private let PATH_RANGE_TOLERANCE: Double         = 50    /// 단위 미터(m)
    static private let MINIMUM_RIDING_VELOCITY: Double      = 0.5   /// 단위 m/sec
    static private let RIDING_VELOCITY_THRESHOLD: Double    = 16    /// 단위 m/sec
    static private let PUBLIC_PLACE_SEARCH_RADIUS: Double   = 500.0 /// 단위는 미터(m)
    
    
    
    // MARK: Member Variables
    
    /// 첫 앱 실행 시 현재 위치로 이동시키기 위한 변수
    public var currentLocation: CLLocation?
    
    /// 첫 앱 실행 시 현재 위치로 이동시키기 위한 변수
    public var currentAddress: String?
    
    /// 맵에 표시될 경로
    private var navigationRoute: GMSPolyline?
    
    /// 맵에 표시될 경로의 꼭지점들
    private var navigationPath: GMSMutablePath?
    
    /// 경유지들의 정보
    private var routeWaypoints: [Waypoint] = []
    
    /// 경유지에 표시될 마커
    private var waypointsMarker: [GMSMarker] = []
    
    /// 목적지에 표시될 마커
    private var destinationMarker: GMSMarker?

    /// 주행 기록
    private var record: Record?
    
    /// 주행 기록의 위치 정보
    private var traces: [Trace] = []
    
    /// 현재 위치의 주변 공공장소를 보관
    private var placesResult:[PublicPlace] = []
    
    /// 현재 위치의 주변 공공장소를 지도에 표시해줄 마커
    private var placesMarkers:[String:GMSMarker] = [:]
    
    /// 마지막으로 경유한 곳을 저장
    private var lastGuidedIndex: Int = -1
    
    /// 네비게이션에 사용될 MapView
    private var navigationMapView: GMSMapView
    
    /// 주행 시작 시간
    private var startDateTime: Date?
    
    // MARK: Initializer
    
    init(mapView: GMSMapView) {
        navigationMapView = mapView
    }
    
    
    
    // MARK: Public Variables
    
    public var currentStatus: NavigationStatus {
        
        guard routeWaypoints.count > 0 else {
            return .freeride
        }
        
        guard
            let currentLocation = navigationMapView.myLocation,
            let navigationPath = navigationPath
        else {
            return .error
        }
        
        guard GMSGeometryIsLocationOnPathTolerance(currentLocation.coordinate, navigationPath, true, NavigationManager.PATH_RANGE_TOLERANCE) else {
            return .offroad
        }
        
        for (index, waypoint) in routeWaypoints.reversed().enumerated() {
            
            let waypointLocation = CLLocation(
                latitude: waypoint.coord.latitude,
                longitude: waypoint.coord.longitude
            )
            
            if currentLocation.distance(from: waypointLocation) < NavigationManager.PATH_RANGE_TOLERANCE {
                
                return index == 0 ? .arrived : .waypoint(routeWaypoints.count - index - 1)
            }
        }
        
        return .onroad
    }
    
    /// 다른 뷰 컨트롤러와 공유할 공공장소 정보들
    public var publicPlaces: [PublicPlace] {
        return placesResult
    }
    
    public var expectedDistance: Double {
        return navigationPath?.length(of: .geodesic) ?? 0
    }
    
    public var estimatedTime: TimeInterval {
        return expectedDistance / 4
    }
    
    public var recordTime: TimeInterval {
        
        guard let startDateTime = startDateTime else {
            return 0
        }
        
        return Date().timeIntervalSince(startDateTime)
    }
    
    public var recordDistance: Double = 0.0
    
    public var recordCalorie: Double {
        
        return recordDistance * 0.03336
    }
    
    // MARK: Private Methods
    
    private func degreesToRadians(degrees: Double) -> Double {
        
        return degrees * .pi / 180.0
    }
    
    private func radiansToDegrees(radians: Double) -> Double {
        
        return radians * 180.0 / .pi
    }
    
    
    
    // MARK: Public Methods
    
    /// 마지막 위치와 비교하여 진행 방향을 계산해 반환
    public func calculateBearing(to : CLLocation) -> CLLocationDirection {
        
        guard let from = traces.last else {
            return -1
        }
        
        let lat1 = degreesToRadians(degrees: from.latitude)
        let lon1 = degreesToRadians(degrees: from.longitude)
        
        let lat2 = degreesToRadians(degrees: to.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: to.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    /// 싱글톤 패턴이 사용 된, 도착지 마커를 맵 위에 설정
    public func setDestination(coord: CLLocationCoordinate2D, name:String, address: String?) {
        
        if destinationMarker == nil {
            let marker = GMSMarker()
            marker.icon = UIImage(named:"arrival")
            
            destinationMarker = marker
        }
        
        guard let marker = destinationMarker else {
            return
        }
        
        marker.map = nil     // Clear previous marker from map
        
        marker.position = coord
        marker.title = name
        marker.snippet = address ?? LiteralString.unknown.rawValue
    }
    
    /// 도착지 마커를 삭제
    public func removeDestination() {
        
        destinationMarker?.map = nil
        destinationMarker = nil
    }
    
    /// T Map GeoJSON API로 현재 위치에서 목적지 까지의 경로를 가져온다
    public func getGeoJSONFromTMap(failure: @escaping (Error) -> Void, success: @escaping (Data) throws -> Void) {
        
        guard
            let currentCoord = navigationMapView.myLocation?.coordinate
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
        
        urlString.append(urlParams.reduce("?") { (url: String, param: (key: String, value: String)) -> String in
            
            var url: String = url
            var param: (key: String, value: String) = param
            
            param.key.append("=")
            param.key.append(param.value)
            param.key.append("&")
            
            url.append(param.key)
            
            return url
        })
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
    public func setRouteAndWaypoints(from data: GeoJSON) {
        
        routeWaypoints = []
        lastGuidedIndex = -1    // 마지막에 음성안내 된 인덱스 -1로 초기화
        
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
            
            let placeName = $0.properties?.name ?? ""
            let description = $0.properties?.description ?? ""
            
            if case let .single(coord) = coordinates {
                
                let coordinate = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                // print(coordinate)    // FOR DEBUG
                path.add(coordinate)
                
                // print(description)
                routeWaypoints.append(Waypoint(coord: coordinate, placeName: placeName, description: description))
            } else if case let .array(coords) = coordinates {
                coords.forEach { coord in
                    
                    let coordinate = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                    // print(coordinate)    // FOR DEBUG
                    path.add(coordinate)
                }
            }
        }
    }
    
    /// T Map으로 부터 받아온 경로를 맵에 그림
    public func drawRoute() {
        
        navigationRoute?.map = nil     // Clear previous route from map
        
        navigationRoute = GMSPolyline(path: navigationPath)
        navigationRoute?.strokeWidth = 5
        navigationRoute?.strokeColor = UIColor.primary
        
        DispatchQueue.main.async {
            self.navigationRoute?.map = self.navigationMapView
        }
    }
    
    public func geoCoder(failure: @escaping (Error) -> Void, success: @escaping (String?) -> Void) {
        
        guard let coordinate = currentLocation?.coordinate else {
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Cannot find current location"
                ]
            )
            
            failure(error)
            return
        }
        
        GMSGeocoder().reverseGeocodeCoordinate(coordinate) { response, error in
            
            guard error == nil else {
                
                failure(error!)
                return
            }
            
            let address = response?.firstResult()?.thoroughfare
            
            self.currentAddress = address
            success(address)
        }
    }
    
    /// 맵에 공공장소를 표시하였던 것을 지움
    public func clearAllPlaces() {
        
        let markers = placesMarkers.values
        DispatchQueue.main.async {
            for marker in markers {
                marker.map = nil
            }
        }
        
        placesMarkers.removeAll()
    }
    
    /// 맵에 공공장소를 표시하거나 갱신 함
    public func showPlaces(in bound: GMSCoordinateBounds) {
        
        let geoBox = navigationMapView.geoBox    // 현재 맵에서 보이는 사각 뷰의 좌하단, 우상단 좌표(위도, 경도)
        
        // Realm GeoQuery를 통해 맵에 보이는 부분에 해당하는 공공 장소들을 갖고 옴
        placesResult = Array(try! Realm().findInBox(type: PublicPlace.self, box: geoBox))
        
        // 현재 뿌려져 있는 마커들 중 보이지 않게 된 마커들을 맵에서 지움
        for (id, marker) in placesMarkers {
            
            if bound.contains(marker.position) == false {
                
                DispatchQueue.main.async {
                    marker.map = nil
                }
                
                if let index = placesMarkers.index(forKey: id) {
                    placesMarkers.remove(at: index)
                }
            }
        }
        
        //  이미 보이는 마커를 제외한 새 마커들을 맵에 그려줌
        for place in placesResult {
            
            if placesMarkers[place.id] == nil {
                
                if case .none = place.placeType {
                    continue
                }
                
                let placeLocation = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng)
                let marker = GMSMarker(position: placeLocation)
                
                marker.icon = UIImage(named: place.placeType.imageName)
                marker.userData = place
                
                DispatchQueue.main.async {
                    marker.map = self.navigationMapView
                }
                
                placesMarkers[place.id] = marker
            }
        }
    }
    
    /// Clear previous marker from map
    public func clearMarkers() {
        
        for marker in waypointsMarker {
            marker.map = nil
        }
        
        waypointsMarker.removeAll()
    }
    
    /// 경유지와 도착지에 마커를 맵에 뿌림
    public func showMarkers() {
        
        clearMarkers()
        
        var waypointCount = 0
        for waypoint in routeWaypoints {
            let marker = GMSMarker()
            let markerIconView = Bundle.main.loadNibNamed("WaypointMarker", owner: BiPeopleNavigationViewController.self, options: nil)?.first as? WaypointMarker
            
            waypointCount += 1
            
            markerIconView?.numberLabel.text = "\(waypointCount)"
            marker.iconView = markerIconView
            
            marker.position = waypoint.coord
            marker.title = waypoint.placeName
            marker.snippet = waypoint.description
            
            waypointsMarker.append(marker)
        }
        
        DispatchQueue.main.async {
            self.destinationMarker?.map = self.navigationMapView
            
            for marker in self.waypointsMarker {
                marker.map = self.navigationMapView
            }
        }
    }
    
    /// 음성 안내
    public func guideWithVoice(at index: Int) {
        
        var speechString: String = ""
        var speechType: AVSpeechBoundary = .word
        switch index {
            
        case Int.max:
            print("종료")
            speechString = "기록을 종료합니다"
            speechType = .immediate
            
        case Int.min:
            print("경로이탈")
            speechString = "경로를 재설정 합니다"
            speechType = .immediate
            
        case _ where routeWaypoints.count == 0 && lastGuidedIndex < index:
            print("자유주행")
            speechString = "기록을 시작합니다"
            speechType = .immediate
            
        case _ where (0 <= index && index < routeWaypoints.count) && lastGuidedIndex < index:
            print(routeWaypoints[index].description)
            speechString = routeWaypoints[index].description
            
        default:
            return
        }
        
        let utterance = AVSpeechUtterance(string: speechString)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.4
        
        SpeechHelper.shared.say(utterance, type: speechType)
        
        lastGuidedIndex = index
    }
    
    /// 경로 및 목적지 초기화
    public func clearRoute() {
        
        navigationPath = nil
        
        navigationRoute?.map = nil
        navigationRoute = nil
        
        routeWaypoints = []
        clearMarkers()
        
        removeDestination()
    }
    
    /// 경로 데이터를 초기화
    public func initDatas() throws {
        
        // 멤버변수 초기화
        startDateTime   = Date()
        recordDistance  = 0.0
        currentAddress  = LiteralString.unknown.rawValue
        lastGuidedIndex = -1
        
        guard
            let currentLocation = navigationMapView.myLocation
        else {
            record = nil
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Cannot find current location"
                ]
            )
            
            throw error
        }
        
        try! Realm().write {
            record = Record(flag: true)
            traces = []
        }
        
        // 위치를 통해 지명을 가져온다
        GMSGeocoder().reverseGeocodeCoordinate(currentLocation.coordinate) { response, error in
            
            guard error == nil else {
                print("Reverse Geocode from current coordinate failed with error: ", error!)    // FOR DEBUG
                return
            }
            
            guard let record = self.record else {
                print("Record is not ready")    // FOR DEBUG
                return
            }
            
            guard
                let address = response?.firstResult()?.thoroughfare
            else {
                print("Reverse Geocode result is empty")    // FOR DEBUG
                return
            }
            
            self.currentAddress = address
            try! Realm().write {
                record.departure = address
            }
        }
    }
    
    /// 경로 데이터에 위치 정보를 추가
    public func addTrace(location: CLLocation) throws {
        
        guard let record = record else {
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Record must be initialized before addTrace"
                ]
            )
            
            throw error
        }
        
        guard location.horizontalAccuracy < NavigationManager.PATH_RANGE_TOLERANCE else {
            return
        }
        
        try! Realm().write {
            
            if let last = traces.last {
                
                let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
                record.distance += location.distance(from: lastLocation)
                
                print("Speed: ", String(location.speed))
                switch location.speed {
                    
                    case _ where location.speed < 0: fallthrough
                    case _ where location.speed > NavigationManager.RIDING_VELOCITY_THRESHOLD:

                        print("Speed ​​measurement error due to low GPS reception rate")     // FOR DEBUG
                    
                    case _ where location.speed < NavigationManager.MINIMUM_RIDING_VELOCITY :
                        
                        record.restTime += location.timestamp.timeIntervalSince(last.timestamp)
                        print("Rest Time... \(record.restTime),")     // FOR DEBUG
                        fallthrough
                    default:
                        record.maximumSpeed = max(record.maximumSpeed, location.speed)
                }
            }
            
            if let last = traces.last {
                
                let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
                recordDistance += location.distance(from: lastLocation)
            }
            
            let trace = Trace(recordID: record._id, location : location)
            traces.append(trace)
        }
    }
    
    /// 경로 데이터를 저장
    public func saveData() throws {
        
        guard let record = record else {
            
            let error = NSError(
                domain: Bundle.main.bundleIdentifier ?? "nil",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey : "Record must be initialized before addTrace"
                ]
            )
            
            throw error
        }
        
        try! Realm().write {
            
            if let firstTrace = traces.first, let lastTrace = traces.last {
                
                record.arrival = currentAddress ?? LiteralString.unknown.rawValue
                record.ridingTime = lastTrace.timestamp.timeIntervalSince(firstTrace.timestamp)
                
                let excerciseTime = record.ridingTime - record.restTime
                record.calories = record.distance * 0.03336
                record.averageSpeed = excerciseTime > 0 ? record.distance / excerciseTime : 0
                
                record.distance /= 1000.0
            }
        }

        RealmHelper.add(data: record)
        RealmHelper.add(datas: traces)
    }
}
