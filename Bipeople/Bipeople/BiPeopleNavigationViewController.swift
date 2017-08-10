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
        
        //
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
        // GMS(Google Mobile Service) 장소 자동완성 검색기능 설정
        resultsViewController = GMSAutocompleteResultsViewController()
        searchPlaceController = UISearchController(searchResultsController: resultsViewController)
        
        resultsViewController.delegate = self
        searchPlaceController.searchResultsUpdater = resultsViewController
        
        // 장소 검색창을 네비게이션 타이틀 위치에 삽입
        searchPlaceController.searchBar.sizeToFit()
        self.navigationItem.titleView = searchPlaceController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchPlaceController.hidesNavigationBarDuringPresentation = false
    }
}

/// CoreLocation 네비게이션 작동 시에 사용
extension BiPeopleNavigationViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
        
        if navigationMapView.isHidden {
            navigationMapView.isHidden = false
            navigationMapView.camera = camera
        } else {
            navigationMapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            navigationMapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

extension BiPeopleNavigationViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        pickPlace(coordinate)
    }
    
    func pickPlace(_ coordinate: CLLocationCoordinate2D) {
        let VIEWPORT_DELTA = 0.001
        
        let northEast = CLLocationCoordinate2DMake(coordinate.latitude + VIEWPORT_DELTA, coordinate.longitude + VIEWPORT_DELTA)
        let southWest = CLLocationCoordinate2DMake(coordinate.latitude - VIEWPORT_DELTA, coordinate.longitude - VIEWPORT_DELTA)
        
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        
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
            
            self.navigationManager.setMarker(
                location: selectedPlace.coordinate,
                name: selectedPlace.name,
                address: selectedPlace.formattedAddress
            )
            
            print(selectedPlace.name)
            
            // 해당 위치에 지명이 딸린 마커를 생성한다
        }
    }
}

/// 구글 장소 자동완성 기능
extension BiPeopleNavigationViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        searchPlaceController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress ?? "Unknown")")
        print("Place attributions: \(place.attributions ?? NSAttributedString())")
        
        /// 선택된 장소로 카메라를 이동
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: zoomLevel)

        if navigationMapView.isHidden {
            navigationMapView.isHidden = false
            navigationMapView.camera = camera
        } else {
            navigationMapView.animate(to: camera)
        }
        
        self.navigationManager.setMarker(
            location: place.coordinate,
            name: place.name,
            address: place.formattedAddress
        )
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
