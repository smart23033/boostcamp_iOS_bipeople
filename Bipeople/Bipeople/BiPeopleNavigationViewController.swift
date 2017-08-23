//
//  BiPeopleNavigationViewController.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 9..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import RealmSwift
import CoreLocation
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import GeoQueries
import MarqueeLabel

enum LiteralString: String {
    case tracking = "Tracking..."
    case apptitle = "BiPeople"
    case unknown = "Unknown"
}

class BiPeopleNavigationViewController: UIViewController {
    
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
    @IBOutlet weak var startButton: UIButton!
    
    /// 현재 위치 주변 공공장소를 보여줄지를 결정할 버튼
    @IBOutlet weak var placesButton: UIButton! 
    
    /// 네비게이션에 사용 될 MapView
    @IBOutlet weak var navigationMapView: GMSMapView! {
        didSet {
            navigationMapView.settings.scrollGestures = true
            navigationMapView.settings.zoomGestures = true
            navigationMapView.settings.consumesGesturesInView = false;
            navigationMapView.settings.myLocationButton = true
            navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            navigationMapView.isMyLocationEnabled = true

            let seoul = CLLocationCoordinate2D(
                latitude: 37.541,
                longitude: 126.986
            )
            
            let camera = GMSCameraPosition.camera(
                withTarget: seoul,
                zoom: 100
            )

            navigationMapView.camera = camera
        }
    }
    
    /// 맵을 Reloading 할 때 보여줄 Indicator
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    
    /// 구글 장소 자동완성 검색창
    lazy private var searchPlaceController: UISearchController = {
        
        // GMS(Google Mobile Service) 장소 자동완성 검색기능 설정
        let resultsViewController = GMSAutocompleteResultsViewController()
        let innerSearchPlaceController = UISearchController(searchResultsController: resultsViewController)
        
        resultsViewController.delegate = self
        innerSearchPlaceController.searchResultsUpdater = resultsViewController
        
        // 장소 검색창을 네비게이션 타이틀 위치에 삽입
        // innerSearchPlaceController.searchBar.sizeToFit()
        
        // Prevent the navigation bar from being hidden when searching...
        innerSearchPlaceController.hidesNavigationBarDuringPresentation = false
        innerSearchPlaceController.searchBar.placeholder = "장소 검색"
        innerSearchPlaceController.searchBar.tintColor = UIColor.primary
        
        return innerSearchPlaceController
    } ()
    
    /// 좌에서 우로 흘러가며 앞글자는 사라지고, 뒷글자는 보이는 Label
    lazy private var marqueeTitle : MarqueeLabel = {
        
        let label = MarqueeLabel()
        
        label.frame = self.view.frame
        label.textAlignment = .center
        label.type = .continuous
        label.speed = .duration(10)
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.white
        
        return label
    } ()
    
    /// navigationItem에서 보이지 않게 하기 위해 nil로 만들면
    /// @IBOutlet weak ~Button들이 메모리 해제 되는 것을 막기 위해 저장
    private var navigationButtons: [String:UIBarButtonItem] = [:]
    
    private var currentLocation: CLLocation?    /// 첫 앱 실행 시 현재 위치로 이동시키기 위한 변수
    
    private var navigationManager: NavigationManager!   /// 네비게이션 모드 책임
    private var locationManager: CLLocationManager!     /// 위치정보 책임
    
    private var zoomLevel: Float = 15.0                 /// 카메라 줌인 정도
    
    /// 네비게이션 모드가 실행되거나 종료될 때, UI의 변화를 책임
    private var isNavigationOn: Bool = false {
        willSet(newVal) {
            startButton.isHidden = true
            if newVal {
                do {
                    try self.navigationManager.initDatas()
                    
                    marqueeTitle.text = LiteralString.tracking.rawValue
                    
                    self.navigationItem.titleView = marqueeTitle
                    self.navigationItem.leftBarButtonItem = navigationButtons["cancel"]
                    self.navigationItem.rightBarButtonItem = navigationButtons["done"]
                    self.navigationMapView.settings.myLocationButton = false
                } catch {
                    
                    print("Initialize datas failed with error: ", error)
                    self.isNavigationOn = false
                    
                    let warningAlert = UIAlertController(
                        title: "네비게이션 모드 전환에 실패하였습니다",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    warningAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    
                    self.present(warningAlert, animated: true)
                }
                
            } else {
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.titleView = searchPlaceController.searchBar
                self.navigationMapView.settings.myLocationButton = true
                self.navigationMapView.clear()
            }
        }
    }
    
    /// 마커가 선택 된 경우, 맵을 선택한 경우 마커 선택이 해제되도록
    private var selectedMarker: GMSMarker? 

    /// 네비게이션 모드에서 터치 시, 5초 가량 현재위치 화면고정 해제
    private var timeUnlocked: TimeInterval = Date().timeIntervalSince1970
    
    override func viewDidLoad() {
        
        /*******************************************************************************************/
        // 공공장소 세부사항 View에서 검색창이 사라지면서 네비게이션 바 아래에 검정줄이 생기는 것을 해결
        self.navigationController?.navigationBar.isTranslucent = true;
        UIBarButtonItem.appearance(whenContainedInInstancesOf:[UISearchBar.self]).tintColor = UIColor.white
        
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
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10     // 이전 위치에서 얼마나 거리차가 나면 위치변경 트리거를 실행할지 결정
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        locationManager.delegate = self
        
        
        /*******************************************************************************************/
        // NavigationManager 초기화
        navigationManager = NavigationManager(mapView: navigationMapView)
    }
    
    /// 네비게이션 모드를 시작하고 주행 정보를 기록하는 버튼
    @IBAction func didTapStartButton(_ sender: Any) {
        
        let confirmAlert = UIAlertController(
            title: "주행 기록을 시작하시겠습니까?",
            message: nil,
            preferredStyle: .alert
        )
        confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.isNavigationOn = true
            
            self.navigationManager.voiceGuidance(index: Int.min)
        })
        
        self.present(confirmAlert, animated: true)
    }
    
    /// 현재 까지의 주행기록을 취소하는 버튼
    @IBAction func didTapCancelButton(_ sender: Any) {
        
        let confirmAlert = UIAlertController(
            title: "정말 기록을 중지하시겠습니까?",
            message: "현재 까지의 기록은 저장되지 않고 종료됩니다",
            preferredStyle: .alert
        )
        confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationManager.voiceGuidance(index: Int.max)
            
            self.isNavigationOn = false
        })
        
        self.present(confirmAlert, animated: true)
    }
    
    /// 현재 까지의 주행기록을 저장하는 버튼
    @IBAction func didTapDoneButton(_ sender: Any) {
        
        let confirmAlert = UIAlertController(
            title: "정말 기록을 중지하시겠습니까?",
            message: "현재 까지의 기록을 저장하고 종료합니다",
            preferredStyle: .alert
        )
        confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationManager.voiceGuidance(index: Int.max)
            
            self.isNavigationOn = false
            self.trySaveData()
        })
        
        self.present(confirmAlert, animated: true)
    }
    
    /// 보이는 화면에 공공장소를 토글하는 버튼
    @IBAction func didTapPlacesButton(_ sender: Any) {
        
        placesButton.isSelected = !placesButton.isSelected
        
        if placesButton.isSelected {
            
            let placesCount = try! Realm().objects(PublicPlace.self).count
            guard placesCount > 0 else {        // 아직 데이터를 받아 오지 못한 경우
                placesButton.isSelected = false
                
                let warningAlert = UIAlertController(
                    title: "아직 공공데이터를 받아오지 못하였습니다",
                    message: "다시 시도하시겠습니까?(2초 후 자동으로 사라집니다)",
                    preferredStyle: .alert
                )
                warningAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
                warningAlert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    self.didTapPlacesButton(sender)
                })
                
                self.present(warningAlert, animated: true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    warningAlert.dismiss(animated: true, completion: nil)
                }
                
                return
            }
            
            let bound = GMSCoordinateBounds(region: navigationMapView.projection.visibleRegion())
            navigationManager.showPlaces(in: bound)
        } else {
            navigationManager.clearAllPlaces()
        }
    }
    
    /// t초 가량 화면 고정을 해제
    private func unpinScreen(for second: Double) {
        timeUnlocked = Date().timeIntervalSince1970 + second
    }
    
    @IBAction func didTapView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    @IBAction func didPinchView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    @IBAction func didRotateView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    @IBAction func didSwipeView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    @IBAction func didPanView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    @IBAction func didEdgePanView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    @IBAction func didLongPressView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    /// 현재위치에서 목적지까지의 경로를 갖고와 맵에 표시
    private func getRouteAndDrawForDestination() {
        
        navigationMapView.isHidden = true  // 경로 파싱이 완료 될 때까지 맵 감춤
        loadingIndicatorView.startAnimating()
        
        navigationManager.getGeoJSONFromTMap(failure: { (error) in
            
            print("getGeoJSONFromTMap failed with error: ", error)
            
            let warningAlert = UIAlertController(
                title: "경로를 가져오는데 실패했습니다",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            warningAlert.addAction(UIAlertAction(title: "확인", style: .default))
            
            self.present(warningAlert, animated: true) {
                
                self.loadingIndicatorView.stopAnimating()
                self.navigationMapView.isHidden = false
                
                self.startButton.isHidden = true
            }
        }) { data in
            // print("data: ", String(data:data, encoding: .utf8) ?? "nil")    // FOR DEBUG
            
            let geoJSON = try JSONDecoder().decode(
                GeoJSON.self,
                from: data
            )
            
            self.navigationManager.setRouteAndWaypoints(from: geoJSON)
            self.navigationManager.drawRoute()
            
            self.navigationManager.showMarkers()
            
            self.loadingIndicatorView.stopAnimating()
            self.navigationMapView.isHidden = false
            self.startButton.isHidden = self.isNavigationOn
        }
    }
    
    /// 주행 기록을 저장
    private func trySaveData() {
        do {
            try self.navigationManager.saveData()
            
            let confirmAlert = UIAlertController(
                title: "주행기록 저장에 성공하였습니다",
                message: "",
                preferredStyle: .alert
            )
            confirmAlert.addAction(UIAlertAction(title: "확인", style: .default))
            
            self.present(confirmAlert, animated: true)
        } catch {
            let warningAlert = UIAlertController(
                title: "주행기록 저장에 실패하였습니다",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            warningAlert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                self.isNavigationOn = false
            })
            warningAlert.addAction(UIAlertAction(title: "재시도", style: .default) { _ in
                self.trySaveData()     // 주의 - 재귀함수
            })
            
            self.present(warningAlert, animated: true)
        }
    }
    
    /// 맵을 coordinate 위치로 이동시키고, bearing 방향으로 회전시킴
    func moveMap(coordinate: CLLocationCoordinate2D?, bearing: CLLocationDirection = -1) {
        
        guard let coord = coordinate else {
            return
        }
        
        let camera = GMSCameraPosition.camera(
            withTarget: coord,
            zoom: zoomLevel,
            bearing: bearing,
            viewingAngle: -1
        )
        
        if navigationMapView.isHidden {
            
            loadingIndicatorView.stopAnimating()
            navigationMapView.isHidden = false
            
            DispatchQueue.main.async {
                self.navigationMapView.camera = camera
            }
        } else {
            navigationMapView.animate(to: camera)
        }
    }
}

/// CoreLocation 네비게이션 작동 시에 사용
extension BiPeopleNavigationViewController: CLLocationManagerDelegate {
    
    /// 위치 변화 이벤트 핸들러
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let updatedLocation = locations.last else {
            print("Location is nil")
            return
        }
        
        // print("Updated Location: ", updatedLocation)    // FOR DEBUG
        
        if currentLocation == nil {
        
            currentLocation = updatedLocation
            moveMap(coordinate: currentLocation?.coordinate)
        }
        
        // 네비게이션 모드가 켜져있는 경우
        // 1. 맵의 중심을 현재 위치로
        // 2. 위치 변화 정보 저장
        // 3. 현재 위치를 NavigationBar Title로(Async)
        // 4. 목적지 도착을 확인 후, 도착한 경우 기록 저장 및 안내 종료
        // 5. 중간 경유지를 지나가는 경우 음성 안내
        // 6. 현재 위치를 이용 해 경로에서 50m 밖을 벗어났는 지를 확인
        //    벗어난 경우 현 위치에서 목적지 까지 새로운 경로를 구해 안내(Async)
        if isNavigationOn {
            
            // 1. 맵의 중심을 현재 위치로
            if timeUnlocked < Date().timeIntervalSince1970 {
                let bearing = navigationManager.calculateBearing(to: updatedLocation)
                moveMap(coordinate: updatedLocation.coordinate, bearing: bearing)
            }
            
            // 2. 위치 변화 정보 저장
            do {
                try navigationManager.addTrace(location: updatedLocation)
            } catch {
                print("Save trace data failed with error: ", error)
            }
            
            // 3. 현재 위치를 NavigationBar Title로(Async)
            GMSGeocoder().reverseGeocodeCoordinate(updatedLocation.coordinate) { response, error in
                
                guard error == nil else {
                    print("Reverse Geocode from current coordinate failed with error: ", error!)    // FOR DEBUG
                    self.marqueeTitle.text = LiteralString.tracking.rawValue
                    
                    return
                }
                
                guard
                    let address = response?.firstResult()
                else {
                    print("Reverse Geocode result is empty")    // FOR DEBUG
                    self.marqueeTitle.text = LiteralString.unknown.rawValue
                    
                    return
                }
                
                self.marqueeTitle.text = address.thoroughfare ?? LiteralString.unknown.rawValue
            }
            
            // 4. 목적지 도착을 확인 후, 도착한 경우 기록 저장 및 안내 종료
            if navigationManager.isArrived {
                navigationManager.voiceGuidance(index: Int.max)
                
                isNavigationOn = false
                trySaveData()
            }
            else {
                
                // 5. 중간 경유지를 지나가는 경우 음성 안내
                let waypointIndex = navigationManager.isInWayPoint
                if waypointIndex >= 0 {
                    navigationManager.voiceGuidance(index: waypointIndex)
                }
                // 6. 현재 위치를 이용 해 경로에서 50m 밖을 벗어났는 지를 확인
                //    벗어난 경우 현 위치에서 목적지 까지 새로운 경로를 구해 안내(Async)
                else if navigationManager.isAwayFromRoute {
                    
                    let warningAlert = UIAlertController(
                        title: "경로 이탈",
                        message: "경로를 재설정 합니다(3초 후 자동으로 사라집니다)",
                        preferredStyle: .alert
                    )
                    warningAlert.addAction(UIAlertAction(title: "종료(저장)", style: .destructive){ _ in
                        self.navigationManager.voiceGuidance(index: Int.max)
                        
                        self.isNavigationOn = false
                        self.trySaveData()
                    })
                    warningAlert.addAction(UIAlertAction(title: "종료(취소)", style: .cancel){ _ in
                        self.navigationManager.voiceGuidance(index: Int.max)
                        
                        self.isNavigationOn = false
                    })
                    self.present(warningAlert, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                        warningAlert.dismiss(animated: true, completion: nil)
                    }
                    
                    navigationManager.voiceGuidance(index: Int.min)
                    getRouteAndDrawForDestination()
                }
            }
        }
    }
    
    /// 위치 권한 변화 이벤트 핸들러
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted...")      // FOR DEBUG
        
        case .denied:
            print("User denied access to location...")      // FOR DEBUG
            
            navigationMapView.isHidden = true
            loadingIndicatorView.startAnimating()
            
            // Alert 문을 띄우고 앱 이용을 위해 위치 권한이 필요함을 알리고
            // 확인을 누르면 환경설정 탭으로, 종료를 누르면 앱을 종료
            let warningAlert = UIAlertController(
                title: "Bipeople을 사용하기 위해서는 위치 정보 권한이 필요합니다",
                message: "사용을 위해 확인을 눌러 환경설정으로 이동한 후 위치 권한을 승인해주세요",
                preferredStyle: .alert
            )
            
            warningAlert.addAction(UIAlertAction(title: "이동", style: .default) { _ in
                
                guard
                    let settingsUrl = URL(string: UIApplicationOpenSettingsURLString),
                    UIApplication.shared.canOpenURL(settingsUrl)
                else {
                    return
                }
    
                UIApplication.shared.open(settingsUrl) { result in
                    print("Settings open ", (result ? "success" : "failed"))
                }
            })
            
            warningAlert.addAction(UIAlertAction(title: "종료", style: .destructive) { _ in
                exit(EXIT_SUCCESS)
            })
            
            self.present(warningAlert, animated: true)
        
        case .notDetermined:
            print("Location status not determined...")      // FOR DEBUG
        
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK...")               // FOR DEBUG
        }
    }
    
    /// 위치 정보 에러 처리 핸들러
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("Location update fail with: ", error)
    }
}

/// 구글 맵뷰 Delegate
extension BiPeopleNavigationViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        selectedMarker = marker
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {

        guard
            let infoWindow = Bundle.main.loadNibNamed("MarkerInfoWindow", owner: self, options: nil)?.first as? MarkerInfoWindow,
            let place = marker.userData as? PublicPlace
        else {
            return nil
        }

        infoWindow.nameLabel.text = place.title
 
        return infoWindow
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        
        let storyboard = UIStoryboard(name: "Navigation", bundle: nil)
        
        guard
            let place = marker.userData as? PublicPlace,
            let placeDetailVC = storyboard.instantiateViewController(withIdentifier: "PlaceDetailViewController") as? PlaceDetailViewController
        else {
            return
        }
        
        placeDetailVC.isNavigationOn = isNavigationOn
        placeDetailVC.selectedPlace = place
        
        // TODO: 필터링
        placeDetailVC.nearPlaces = self.navigationManager.publicPlaces
        
        self.navigationController?.pushViewController(placeDetailVC, animated: true)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        let bound = GMSCoordinateBounds(region: navigationMapView.projection.visibleRegion())
        
        // 현재 위치 주변 공공장소 보여주기
        if placesButton.isSelected {
            navigationManager.showPlaces(in: bound)
        } else {
            navigationManager.clearAllPlaces()
        }
        
        guard let marker = selectedMarker else {
            return
        }
        
        if bound.contains(marker.position) == false {
            selectedMarker = nil
        }
    }
    
    /// 맵에서 위치가 선택(터치)된 경우
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
        guard isNavigationOn == false, selectedMarker == nil else {
            selectedMarker = nil
            return
        }
        
        let VIEWPORT_DELTA = 0.001 // 선택된 지점 주변 반경(맵에서 보여줄)
        
        let northEast = CLLocationCoordinate2DMake(coordinate.latitude + VIEWPORT_DELTA, coordinate.longitude + VIEWPORT_DELTA) //   ㄱ
        let southWest = CLLocationCoordinate2DMake(coordinate.latitude - VIEWPORT_DELTA, coordinate.longitude - VIEWPORT_DELTA) // ㄴ
        
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        
        let config = GMSPlacePickerConfig(viewport: viewport)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        
        // Display the place picker. This will call the delegate methods defined below when the user
        // has made a selection.
        self.present(placePicker, animated: true)
    }
}

/// 장소를 맵을 선택(터치)하여 선택해서
extension BiPeopleNavigationViewController: GMSPlacePickerViewControllerDelegate {
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        
        // FOR DEBUG
        print("Selected Place name: ", place.name)
        print("Selected Place address: ", place.formattedAddress ?? LiteralString.unknown)
        print("Selected Place attributions: ", place.attributions ?? NSAttributedString())
        
        // Dismiss the place picker.
        viewController.dismiss(animated: true) {
            self.navigationManager.setDestination(at: place)
            self.getRouteAndDrawForDestination()
        }
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didFailWithError error: Error) {
        
        // TODO: handle the error...
        print("place picker fail with : ", error.localizedDescription)
        
        viewController.dismiss(animated: true)
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        
        // FOR DEBUG
        print("The place picker was canceled by the user")
        
        viewController.dismiss(animated: true)
    }
}

/// 구글 장소 자동완성 기능
extension BiPeopleNavigationViewController: GMSAutocompleteResultsViewControllerDelegate {
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        searchPlaceController.isActive = false
        
        // FOR DEBUG
        print("Searched Place name: ", place.name)
        print("Searched Place address: ", place.formattedAddress ?? LiteralString.unknown)
        print("Searched Place attributions: ", place.attributions ?? NSAttributedString())
        
        // 선택된 장소로 화면을 전환하기 위한 카메라 정보
        moveMap(coordinate: place.coordinate)
        
        navigationManager.setDestination(at: place)
        getRouteAndDrawForDestination()
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
