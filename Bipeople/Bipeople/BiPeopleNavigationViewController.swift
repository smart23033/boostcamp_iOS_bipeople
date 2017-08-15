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
    
    /// navigationItem에서 보이지 않게 하기 위해 nil로 만들면
    /// @IBOutlet UIBarButtonItem들이 메모리 해제 되는 것을 막기 위해 저장
    var navigationButtons: [String:UIBarButtonItem]!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!   /// 기록 취소 후 네비게이션 모드 종료
    @IBOutlet weak var doneButton: UIBarButtonItem!     /// 기록 저장 후 네비게이션 모드 종료
    
    /// 네비게이션 주행 시작
    @IBOutlet weak var startButton: UIButton! {
        didSet {
            // 출발 버튼을 원형 플로팅 버튼으로 변경
            startButton.clipsToBounds = true
            startButton.layer.cornerRadius = startButton.frame.width * 0.5
            startButton.layer.shadowColor = UIColor.black.cgColor
            startButton.layer.shadowRadius = 2
            startButton.layer.shadowOpacity = 0.8
            startButton.layer.shadowOffset = CGSize.zero
            startButton.setTitle("출발", for: .normal)
            startButton.setTitleColor(UIColor.white, for: .normal)
            startButton.backgroundColor = UIColor.primary
            startButton.autoresizingMask = []
            
            startButton.isHidden = true
        }
    }
    
    var navigationManager: NavigationManager = .init()
    
    var resultsViewController: GMSAutocompleteResultsViewController!
    var searchPlaceController: UISearchController!

    var locationManager: CLLocationManager = .init()
    var currentLocation: CLLocation?

    var navigationMapView: GMSMapView!
    var zoomLevel: Float = 15.0
    
    var isNavigationOn: Bool = false {
        didSet(oldVal) {
            // startButton.isHidden = true
            startButton.isHidden = oldVal
            if oldVal {
                navigationManager.removeMarker()
                navigationManager.eraseRoute()
                
                self.navigationItem.titleView = searchPlaceController?.searchBar
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = nil
            } else {
                self.navigationItem.titleView = nil
                self.navigationItem.title = "Let's GO!!"
                self.navigationItem.leftBarButtonItem = navigationButtons["cancel"]
                self.navigationItem.rightBarButtonItem = navigationButtons["done"]
            }
        }
    }
    
    override func viewDidLoad() {
        
        navigationButtons = [
            "cancel"    : cancelButton,
            "done"      : doneButton
        ]
        
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        
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
        navigationMapView.settings.myLocationButton = true
        navigationMapView.settings.compassButton = true
        navigationMapView.settings.scrollGestures = true
        navigationMapView.settings.zoomGestures = true
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.settings.myLocationButton = true
        navigationMapView.isMyLocationEnabled = true
        navigationMapView.delegate = self
        
        // 네비게이션 매니저가 사용할 맵뷰로 설정
        navigationManager.setMapView(view: navigationMapView)
        
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
        self.navigationItem.titleView = searchPlaceController.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain...
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching...
        searchPlaceController.hidesNavigationBarDuringPresentation = false
    }
    
    @IBAction func didTapStartButton() {
        
        isNavigationOn = false
        navigationMapView.isHidden = true
        
        self.navigationManager.getGeoJSONFromTMap(failure: { (error) in
            print("Error: ", error)
            self.navigationMapView.isHidden = false
        }) { data in
            print("data: ", String(data:data, encoding: .utf8) ?? "nil")
            
            let geoJSON = try JSONDecoder().decode(
                GeoJSON.self,
                from: data
            )
            
            self.navigationManager.drawRoute(from: geoJSON)
            self.navigationMapView.isHidden = false
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
        
        if isNavigationOn {
            // GMSGeometryIsLocationOnPathTolerance(<#T##point: CLLocationCoordinate2D##CLLocationCoordinate2D#>, <#T##path: GMSPath##GMSPath#>, <#T##geodesic: Bool##Bool#>, <#T##tolerance: CLLocationDistance##CLLocationDistance#>)
        }
        
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
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        
        return Bundle.main.loadNibNamed("MarkerInfoWindow", owner: self, options: nil)?.first as? MarkerInfoWindow
    }
    
    /// 맵에서 위치가 선택(터치)된 경우
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
        let VIEWPORT_DELTA = 0.001 // 선택된 지점 주변 반경(맵에서 보여줄)
        
        let northEast = CLLocationCoordinate2DMake(coordinate.latitude + VIEWPORT_DELTA, coordinate.longitude + VIEWPORT_DELTA) //   ㄱ
        let southWest = CLLocationCoordinate2DMake(coordinate.latitude - VIEWPORT_DELTA, coordinate.longitude - VIEWPORT_DELTA) // ㄴ
        
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        
        let config = GMSPlacePickerConfig(viewport: viewport)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        
        // Display the place picker. This will call the delegate methods defined below when the user
        // has made a selection.
        self.present(placePicker, animated: true, completion: nil)
    }
}

/// 장소를 맵을 선택(터치)하여 선택해서
extension BiPeopleNavigationViewController: GMSPlacePickerViewControllerDelegate {
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        
        // FOR DEBUG
        print("Selected Place Name: ", place.name)
        
        // Dismiss the place picker.
        viewController.dismiss(animated: true) {
            self.navigationItem.titleView = nil
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = nil
            
            // 선택된 지점을 네비게이션 도착지로 결정하고, 도착지 마커를 표시
            try? self.navigationManager.setMarker(
                location: place.coordinate,
                name: place.name,
                address: place.formattedAddress
            )
            
            self.isNavigationOn = true
        }
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didFailWithError error: Error) {
        
        // TODO: handle the error...
        print("place picker fail with : ", error.localizedDescription)
        
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        
        // FOR DEBUG
        print("The place picker was canceled by the user")
        
        viewController.dismiss(animated: true, completion: nil)
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
        
        self.navigationItem.titleView = nil
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = nil
        
        // 장소 검색을 통해 선택된 지점을 도착지로 결정하고, 도착지 마커를 표시
        try? self.navigationManager.setMarker(
            location: place.coordinate,
            name: place.name,
            address: place.formattedAddress
        )
        
        self.isNavigationOn = true
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
