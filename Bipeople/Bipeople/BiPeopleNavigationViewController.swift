//
//  BiPeopleNavigationViewController.swift
//  Bipeople
//
//  Created by CONNECT on 2017. 8. 9..
//  Copyright © 2017년 sikurity. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import GooglePlacePicker

class BiPeopleNavigationViewController: UIViewController {
    
    var navigationManager: NavigationManager = .init()
    
    var resultsViewController: GMSAutocompleteResultsViewController!
    var searchPlaceController: UISearchController!

    var locationManager: CLLocationManager = .init()
    var currentLocation: CLLocation?

    var navigationMapView: GMSMapView!
    var zoomLevel: Float = 15.0
    
    override func viewDidLoad() {
        
        /*******************************************************************************************/
        // CLLocationManager 초기화
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        
        /*******************************************************************************************/
        // Google Map View 높이 설정 - 맵 하단이 탭바 컨트롤러에 가려지는 것을 막기 위해, 탭바 높이 만큼 축소
        let mapViewHeight = view.frame.height - (tabBarController?.tabBar.frame.height ?? 0)
        let mapViewBounds = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: mapViewHeight)
        
        // 카메라 초기화
        let camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: zoomLevel)
        
        // Google Map View 초기화
        navigationMapView = GMSMapView.map(withFrame: mapViewBounds, camera: camera)
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.settings.myLocationButton = true
        navigationMapView.isMyLocationEnabled = true
        navigationMapView.delegate = self
        
        // 네비게이션 매니저가 사용할 맵뷰로 설정
        navigationManager.mapMarkerShowed = navigationMapView
        
        // Map View를 위치가 갱신될 때 까지는, 보이지 않는 상태로 View 최하단에 삽입
        navigationMapView.isHidden = true
        self.view.insertSubview(self.navigationMapView, at: 0)
        
        
        /*******************************************************************************************/
        // 출발 버튼을 생성하여, 우측 하단에 배치
        let posX = navigationMapView.frame.width - 66   // navigationMapView.frame.width * 0.84
        let posY = navigationMapView.frame.height - 210 // navigationMapView.frame.height * 0.7
        
        let lengthOfSide = CGFloat(58)
        
        print("posX: ", posX)
        print("posY: ", posY)
        print("lengthOfSide: ", lengthOfSide)
        
        let startButton = UIButton(frame: CGRect(x: posX, y: posY, width: lengthOfSide, height: lengthOfSide))
        
        startButton.layer.cornerRadius = lengthOfSide * 0.5
        startButton.clipsToBounds = true
        startButton.layer.shadowColor = UIColor.black.cgColor
        startButton.layer.shadowRadius = 2
        startButton.layer.shadowOpacity = 0.8
        startButton.layer.shadowOffset = CGSize.zero
        startButton.setTitle("출발", for: .normal)
        startButton.setTitleColor(UIColor.white, for: .normal)
        startButton.backgroundColor = UIColor.primary
        startButton.autoresizingMask = []
        
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
        
        self.view.addSubview(startButton)
        
        
        /*******************************************************************************************/
        // GMS(Google Mobile Service) 장소 자동완성 검색기능 설정
        resultsViewController = GMSAutocompleteResultsViewController()
        searchPlaceController = UISearchController(searchResultsController: resultsViewController)
        
        resultsViewController.delegate = self
        searchPlaceController.searchResultsUpdater = resultsViewController
        
        // 장소 검색창을 네비게이션 타이틀 위치에 삽입
        searchPlaceController.searchBar.sizeToFit()
        self.navigationItem.titleView = searchPlaceController.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain...
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching...
        searchPlaceController.hidesNavigationBarDuringPresentation = false
    }
    
    @objc func didTapStartButton() {
        
        self.navigationManager.getGeoJSONFromTMap(failure: { (error) in
            print("Error: ", error)
        }) { data in
            print("data: ", String(data:data, encoding: .utf8) ?? "nil")
            
            let routeInfo = try JSONDecoder().decode(
                GeoJSON.self,
                from: data
            )
            
            let path = GMSMutablePath()
            
            if let features = routeInfo.features {
                for feature in features {
                    if let coordinates = feature.geometry?.coordinates {
                        if case let .single(coord) = coordinates {
                            print(coord)
                            path.add(CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]))
                        } else if case let .array(coords) = coordinates {
                            for coord in coords {
                                print(coord)
                                path.add(CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0]))
                            }
                        }
                    }
                }
            }
            
            let route = GMSPolyline(path: path)
            route.map = self.navigationMapView
            
            print("routeInfo: ", routeInfo)
        }
    }
}

/// CoreLocation 네비게이션 작동 시에 사용
extension BiPeopleNavigationViewController: CLLocationManagerDelegate {
    
    /// Handle incoming location events...
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            print("Location is nil")
            return
        }
        
        print("Updated Location: ", location)
        
        let camera = GMSCameraPosition.camera(
            withLatitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            zoom: zoomLevel
        )
        
        // 위치가 업데이트 된 지점으로 맵을 이동
        if navigationMapView.isHidden {
            navigationMapView.isHidden = false
            navigationMapView.camera = camera
        } else {
            navigationMapView.animate(to: camera)
        }
    }
    
    /// FOR DEBUG: Handle authorization for the location manager...
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted...")
        
        case .denied:
            print("User denied access to location...")
            navigationMapView.isHidden = false
            
            // 환경설정 페이지로 이동시켜서 설정하게 만들어야 함
        
        case .notDetermined:
            print("Location status not determined...")
        
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK...")
        }
    }
    
    /// FOR DEBUG: Handle location manager errors...
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("location update fail with: ", error)
    }
}

/// 구글 맵뷰 Delegate
extension BiPeopleNavigationViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        guard let infoWindow = Bundle.main.loadNibNamed("MarkerInfoWindow", owner: self, options: nil)?.first as? MarkerInfoWindow else {
            print("NIL!!")
            return true
        }
        
        infoWindow.center = mapView.projection.point(for: marker.position)
        self.view.addSubview(infoWindow)
        
        return false
    }
    
    /// 맵에서 위치가 선택(터치)된 경우
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    
        let VIEWPORT_DELTA = 0.001 // 선택된 지점 주변 반경(맵에서 보여줄)
        
        let northEast = CLLocationCoordinate2DMake(coordinate.latitude + VIEWPORT_DELTA, coordinate.longitude + VIEWPORT_DELTA) //   ㄱ
        let southWest = CLLocationCoordinate2DMake(coordinate.latitude - VIEWPORT_DELTA, coordinate.longitude - VIEWPORT_DELTA) // ㄴ
        
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        
        // 맵에서 선택(터치)된 지점의 주변 장소 후보들을 보여주는 화면으로 전환
        let placePicker = GMSPlacePicker(config: config)
        placePicker.pickPlace{ (place, error) -> () in
            
            guard error == nil else {
                print(error!)
                return
            }
            
            guard let selectedPlace = place else {
                print("지역 정보를 가져올 수 없습니다")
                return
            }
            
            // 선택된 지점을 네비게이션 도착지로 결정하고, 도착지 마커를 표시
            try? self.navigationManager.setMarker(
                location: selectedPlace.coordinate,
                name: selectedPlace.name,
                address: selectedPlace.formattedAddress
            )
            
            // FOR DEBUG
            print("Selected Place Name: ", selectedPlace.name)
        }
    }
}

/// 구글 장소 자동완성 기능
extension BiPeopleNavigationViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        searchPlaceController?.isActive = false
        
        // FOR DEBUG
        print("Place name: ", place.name)
        print("Place address: ", place.formattedAddress ?? "Unknown")
        print("Place attributions: ", place.attributions ?? NSAttributedString())
        
        // 선택된 장소로 화면을 전환하기 위한 카메라 정보
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: zoomLevel)

        if navigationMapView.isHidden {
            navigationMapView.isHidden = false
            navigationMapView.camera = camera
        } else {
            navigationMapView.animate(to: camera)
        }
        
        // 장소 검색을 통해 선택된 지점을 도착지로 결정하고, 도착지 마커를 표시
        try? self.navigationManager.setMarker(
            location: place.coordinate,
            name: place.name,
            address: place.formattedAddress
        )
    }
    
    /// FOR DEBUG: 장소검색 자동완성에서 에러 발생 시
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error...
        print("result update fail with : ", error.localizedDescription)
    }
    
    /// Turn the network activity indicator on
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    /// Turn the network activity indicator off
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
