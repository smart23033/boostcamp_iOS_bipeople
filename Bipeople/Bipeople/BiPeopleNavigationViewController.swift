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
    /// @IBOutlet weak ~Button들이 메모리 해제 되는 것을 막기 위해 저장
    var navigationButtons: [String:UIBarButtonItem] = [:]
    
    /// 기록 취소 후 네비게이션 모드 종료 버튼
    @IBOutlet weak var cancelButton: UIBarButtonItem! {
        willSet(newVal) {
            navigationButtons["left"] = newVal
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    /// 기록 저장 후 네비게이션 모드 종료 버튼
    @IBOutlet weak var doneButton: UIBarButtonItem! {
        willSet(newVal) {
            navigationButtons["right"] = newVal
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    /// 네비게이션 시작 버튼
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
        }
    }
    
    @IBOutlet weak var navigationMapView: GMSMapView! {
        didSet {
            navigationMapView.settings.myLocationButton = true
            navigationMapView.settings.compassButton = true
            navigationMapView.settings.scrollGestures = true
            navigationMapView.settings.zoomGestures = true
            navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            navigationMapView.isMyLocationEnabled = true
        }
    }
    
    /// 구글 장소 자동완성 검색창
    lazy var searchPlaceController: UISearchController = {
        
        // GMS(Google Mobile Service) 장소 자동완성 검색기능 설정
        let resultsViewController = GMSAutocompleteResultsViewController()
        let innerSearchPlaceController = UISearchController(searchResultsController: resultsViewController)
        
        resultsViewController.delegate = self
        innerSearchPlaceController.searchResultsUpdater = resultsViewController
        
        // 장소 검색창을 네비게이션 타이틀 위치에 삽입
        innerSearchPlaceController.searchBar.sizeToFit()
        
        // Prevent the navigation bar from being hidden when searching...
        innerSearchPlaceController.hidesNavigationBarDuringPresentation = false
        
        return innerSearchPlaceController
    } ()
    
    var navigationManager: NavigationManager!
    var locationManager: CLLocationManager!
    var zoomLevel: Float = 15.0
    
    var isNavigationOn: Bool = false {
        didSet(oldVal) {
            startButton.isHidden = true
            if oldVal {
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.titleView = searchPlaceController.searchBar
                
                self.navigationMapView.clear()
            } else {
                self.navigationItem.titleView = nil
                self.navigationItem.title = "Tracking..."
                self.navigationItem.leftBarButtonItem = navigationButtons["cancel"]
                self.navigationItem.rightBarButtonItem = navigationButtons["done"]
            }
        }
    }
    
    override func viewDidLoad() {
        
        /*******************************************************************************************/
        // 첫 화면에 네비게이션 버튼을 없애고, 장소 검색창이 보이도록 설정
        navigationButtons = [
            "cancel"    : cancelButton,
            "done"      : doneButton
        ]
        
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        navigationItem.titleView = searchPlaceController.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain...
        self.definesPresentationContext = true
        
        /*******************************************************************************************/
        // CLLocationManager 초기화
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 1     // 이전 위치에서 얼마나 거리 차이가 나면 update location을 실행할지 결정
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        
        /*******************************************************************************************/
        // NavigationManager 초기화
        navigationManager = NavigationManager(mapView: navigationMapView)
    }
    
    @IBAction func didTapStartButton(_ sender: Any) {
        
        isNavigationOn = true
    }
    
    
    @IBAction func didTapCancelButton(_ sender: Any) {
        
        isNavigationOn = false
    }
    
    @IBAction func didTapDoneButton(_ sender: Any) {
        
        isNavigationOn = false
    }
    
    func getRouteAndDraw(toward place: GMSPlace) -> (() -> Void) {
        
        return {
            self.navigationMapView.isHidden = true
            
            self.navigationManager.getGeoJSONFromTMap(toward: place, failure: { (error) in
                print("Error: ", error)
                
                self.navigationMapView.isHidden = false
                self.startButton.isHidden = true
            }) { data in
                print("data: ", String(data:data, encoding: .utf8) ?? "nil")
                
                let geoJSON = try JSONDecoder().decode(
                    GeoJSON.self,
                    from: data
                )
                
                self.navigationManager.drawRoute(from: geoJSON)
                self.navigationManager.setMarker(place: place)
                
                self.navigationMapView.isHidden = false
                self.startButton.isHidden = false
            }
        }
    }
}

/// CoreLocation 네비게이션 작동 시에 사용
extension BiPeopleNavigationViewController: CLLocationManagerDelegate {
    
    /// Handle incoming location events...
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let updatedLocation = locations.last else {
            print("Location is nil")
            return
        }
        
        print("Updated Location: ", updatedLocation)
        
        let camera = GMSCameraPosition.camera(
            withLatitude: updatedLocation.coordinate.latitude,
            longitude: updatedLocation.coordinate.longitude,
            zoom: zoomLevel
        )
        
        // 위치가 업데이트 된 지점으로 맵을 이동
        if navigationMapView.isHidden {
            navigationMapView.isHidden = false
            navigationMapView.camera = camera
        } else {
            navigationMapView.animate(to: camera)
        }
        
        // TODO: 기록 저장
        if isNavigationOn {
            // USE GMSGeometryIsLocationOnPathTolerance(location, path, true, 50.0)
            // if navigationManager.isBreakaway(current: location) {
            
            //}
            
            do {
                try navigationManager.addTrace(
                    location: updatedLocation,
                    updatedTime: Date().timeIntervalSince1970
                )
            } catch {
                print("Error Occurred: ", error)
            }
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
            
            // Alert 문을 띄우고 앱 이용을 위해 위치 권한이 필요함을 알리고
            // 확인을 누르면 환경설정 탭으로,
            // 취소를 누르면 앱을 종료해야 함
            
            // TODO: 아래 Logic을 AlertController의 ConfirmButton의 Completion Handler로
//            guard
//                let settingsUrl = URL(string: UIApplicationOpenSettingsURLString),
//                UIApplication.shared.canOpenURL(settingsUrl)
//            else {
//                return
//            }
//
//            UIApplication.shared.open(settingsUrl) {
//                print("Settings open ", $0 ? "success" : "failed")
//            }
        
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
        print("Selected Place name: ", place.name)
        print("Selected Place address: ", place.formattedAddress ?? "Unknown")
        print("Selected Place attributions: ", place.attributions ?? NSAttributedString())
        
        // Dismiss the place picker.
        viewController.dismiss(animated: true, completion: getRouteAndDraw(toward: place))
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
        searchPlaceController.isActive = false
        
        // FOR DEBUG
        print("Searched Place name: ", place.name)
        print("Searched Place address: ", place.formattedAddress ?? "Unknown")
        print("Searched Place attributions: ", place.attributions ?? NSAttributedString())
        
        // 선택된 장소로 화면을 전환하기 위한 카메라 정보
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: zoomLevel)

        if navigationMapView.isHidden {
            navigationMapView.isHidden = false
            navigationMapView.camera = camera
        } else {
            navigationMapView.animate(to: camera)
        }
        
        getRouteAndDraw(toward: place)()
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
