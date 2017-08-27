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



// MARK: Class

class BiPeopleNavigationViewController: UIViewController {
    
    // MARK: Outlets
    
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
    
    /// 주행 정보 창
    @IBOutlet weak var infoView: UIView! 
    
    /// 네비게이션 시작 버튼
    @IBOutlet weak var startButton: UIButton!
    
    /// 예상 경로 취소 버튼
    @IBOutlet weak var clearButton: UIButton!
    
    /// 현재 위치 주변 공공장소를 보여줄지를 결정할 버튼
    @IBOutlet weak var placesButton: UIButton!
    
    /// 주행시간 표시 라벨
    @IBOutlet weak var timeLabel: UILabel!
    
    /// 주행거리 표시 라벨
    @IBOutlet weak var distanceLabel: UILabel!
    
    /// 칼로리 표시 라벨
    @IBOutlet weak var calorieLabel: UILabel!
    
    /// 속도계 표시 라벨
    @IBOutlet weak var speedLabel: UILabel!
    
    /// 네비게이션에 사용 될 MapView
    @IBOutlet weak var navigationMapView: GMSMapView! {
        didSet {
            navigationMapView.settings.scrollGestures = true
            navigationMapView.settings.zoomGestures = true
            navigationMapView.settings.consumesGesturesInView = false;
            navigationMapView.settings.myLocationButton = true
            navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            navigationMapView.isMyLocationEnabled = true
        }
    }
    
    /// 맵을 Reloading 할 때 보여줄 Indicator
    @IBOutlet weak var loadingIndicatorView: UIActivityIndicatorView!
    
    /// 네비게이션 모드 중 주행 정보를 보여줄 화면
    @IBOutlet weak var infoViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: Lazy Variables
    
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
    
//    private var infoViewFrame: CGRect!
//    private var mapViewFrame: CGRect!
    
    // MARK: Private Variables
    
    /// navigationItem에서 보이지 않게 하기 위해 버튼을 nil로 만들면 메모리 해제 되는 것을 막기 위해 저장
    private var navigationButtons: [String:UIBarButtonItem] = [:]
    
    /// 네비게이션 모드 책임
    private var navigationManager: NavigationManager!
    
    /// GPS 정보(위치, 방향, 속도, 고도) 관리자
    private var locationManager: CLLocationManager!
    
    /// 정보 창 라벨 갱신 타이머
    private var recordTimer: Timer?
    
    /// 네비게이션 모드가 실행되거나 종료될 때, UI의 변화를 책임
    private var isNavigationOn: Bool = false {
        willSet(newVal) {
            
            if newVal {
                do {
                    initInfoView()
                    startTimer(selector: #selector(updateInfoView))
                    
                    try navigationManager.initDatas()
                    
                    self.navigationItem.titleView = marqueeTitle
                    
                    self.navigationItem.leftBarButtonItem = navigationButtons["cancel"]
                    self.navigationItem.rightBarButtonItem = navigationButtons["done"]
                    
                    startButton.isHidden = true
                    clearButton.isHidden = true
                    
                    toggleInfoView()
                }
                catch {
                    self.isNavigationOn = false
                    
                    print("Initialize datas failed with error: ", error)
                    let warningAlert = UIAlertController(
                        title: "네비게이션 모드 전환에 실패하였습니다",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    warningAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    
                    self.present(warningAlert, animated: true)
                    
                    stopTimer()
                    initInfoView()
                }
                
            } else {
                self.navigationItem.leftBarButtonItem = nil
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.titleView = searchPlaceController.searchBar
                
                navigationManager.clearRoute()
                
                if #available(iOS 11.0, *) {
                    let navigationBarFrame = CGRect(x: 0 , y: 20, width: self.view.frame.width, height: 64)
                    self.navigationController?.navigationBar.frame = navigationBarFrame
                }
                
                startButton.isHidden = false
                clearButton.isHidden = true
                
                stopTimer()
                initInfoView()
            }
        }
    }
    
    /// 마커가 선택 된 경우, 맵을 선택한 경우 마커 선택이 해제되도록
    private var selectedMarker: GMSMarker?

    /// 네비게이션 모드에서 터치 시, 5초 가량 현재위치 화면고정 해제
    private var timeUnlocked: TimeInterval = Date().timeIntervalSince1970
    
    
    
    // MARK: Life Cycle
    
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
    
    
    
    // MARK: Actions
    
    /// 공공장소에서 이동 버튼을 눌렀을 경우 unwind
    @IBAction func unwindFromPlaceDetailVC(_ segue: UIStoryboardSegue) {
        
        guard
            let placeDetailVC = segue.source as? PlaceDetailViewController,
            let selectedPlace = placeDetailVC.selectedPlace
        else {
            return
        }
        
        unpinScreen(for: 5)

        let placeCoord = CLLocationCoordinate2D(
            latitude: selectedPlace.lat,
            longitude: selectedPlace.lng
        )
        
        moveMap(coordinate: placeCoord)

        if isNavigationOn == false {
            
            navigationManager.setDestination(
                coord: placeCoord,
                name: selectedPlace.title,
                address: selectedPlace.address
            )
            getRouteAndDrawForDestination()
        }
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
            self.navigationManager.guideWithVoice(at: Int.max)
            
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
            self.navigationManager.guideWithVoice(at: Int.max)
            
            self.isNavigationOn = false
            self.trySaveData()
            try? self.navigationManager.initDatas()
        })
        
        self.present(confirmAlert, animated: true)
    }
    
    /// 네비게이션 모드를 시작하고 주행 정보를 기록하는 버튼
    @IBAction func didTapStartButton(_ sender: Any) {
        
        let time = navigationManager.estimatedTime
        let distance = navigationManager.expectedDistance
        
        var title: String
        if distance > 0 {
            title = """
                    주행 기록을 시작하시겠습니까?
                    예상주행시간: \(time.digitalFormat)
                    예상주행거리: \(distance.roundTo(places: 1)) m
                    """
        } 
        else {
            title = "자율 주행 기록을 시작하시겠습니까?"
        }
        
        let confirmAlert = UIAlertController(
            title: title,
            message: nil,
            preferredStyle: .alert
        )
        confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            
            self.isNavigationOn = true
            self.processBasedOnCurrentStatus()
        })
        
        self.present(confirmAlert, animated: true)
    }
    
    /// 네비게이션 모드를 시작하고 주행 정보를 기록하는 버튼
    @IBAction func didTapClearButton(_ sender: Any) {
        
        navigationManager.clearRoute()
        clearButton.isHidden = true
    }
    
    /// 보이는 화면에 공공장소를 토글하는 버튼
    @IBAction func didTapPlacesButton(_ sender: Any) {
        
        unpinScreen(for: 5)
        
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
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didTapView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didPinchView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didRotateView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didSwipeView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didPanView(_ sender: Any) 
    {
        unpinScreen(for: 5)
    }
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didEdgePanView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    /// 사용자가 앱을 사용할 경우, 화면 고정을 5초간 해제
    @IBAction func didLongPressView(_ sender: Any) {
        unpinScreen(for: 5)
    }
    
    
    
    // MARK: Private Methods
    
    /// 인자로 받은 시간만큼 화면 고정을 해제
    private func unpinScreen(for second: Double) {
        timeUnlocked = Date().timeIntervalSince1970 + second
        
        if isNavigationOn {
            toggleInfoView()
        }
    }
    
    /// 화면을 현재 위치로 고정
    private func pinScreen() {
        timeUnlocked = Date().timeIntervalSince1970
        
        if isNavigationOn {
            toggleInfoView()
        }
    }
    
    /// 현재위치에서 목적지까지의 경로를 갖고와 맵에 표시
    private func getRouteAndDrawForDestination(recorded: Bool = false) {
        
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
            
            guard recorded == self.isNavigationOn else {
                return
            }
            
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
            self.clearButton.isHidden = self.isNavigationOn
        }
    }
    
    /// 주행 기록을 저장
    private func trySaveData() {
        do {
            try navigationManager.saveData()
            
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
    private func moveMap(coordinate: CLLocationCoordinate2D?) {
        
        guard let coord = coordinate else {
            return
        }
        
        #if arch(i386) || arch(x86_64)
            let bearing = navigationManager.calculateBearing(to: coord)
            let camera = GMSCameraPosition.camera(
                withTarget: coord,
                zoom: 15.0,
                bearing: bearing,
                viewingAngle: -1
            )
        #else
            let camera = GMSCameraPosition.camera(
                withTarget: coord,
                zoom: 15.0
            )
        #endif
        
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
    
    /// 주행 정보창을 띄우거나 숨김
    private func toggleInfoView() {
        
        if timeUnlocked < Date().timeIntervalSince1970 {    // 화면 고정이 된 상태에서
            if infoView.isHidden == true {                  // 정보 창이 보이지 않는 상태라면
                
                infoView.isHidden = false                   // 정보 창을 보여준다(애니메이션 효과)
                UIView.animate(
                    withDuration: 1.0,
                    delay: 0.0,
                    options: .curveEaseInOut,
                    animations: {
                        
                        let height = self.view.frame.height * 0.3
                        self.infoViewHeightConstraint.constant = height
                        self.view.layoutIfNeeded()
                    },
                    completion: nil
                )
            }
        } else {                                            // 화면 고정되지 않은 상태에서
            if infoView.isHidden == false {                 // 정보 창이 보이는 상태라면
                
                UIView.animate(                             // 정보 창을 감춘다(애니메이션 효과)
                    withDuration: 1.0,
                    delay: 0.0,
                    options: .curveEaseInOut,
                    animations: {
                        
                        self.infoViewHeightConstraint.constant = 0
                        self.view.layoutIfNeeded()
                    }
                ) { _ in
                    self.infoView.isHidden = true
                }
            }
        }
    }
    
    /// 네비게이션에서 현재 위치를 바탕으로 안내를 해줌
    private func processBasedOnCurrentStatus() {
        
        switch navigationManager.currentStatus {
            
        case .arrived:              // 목적지 도착을 확인 후, 도착한 경우 기록 저장 및 안내 종료
            navigationManager.guideWithVoice(at: Int.max)
            
            isNavigationOn = false
            trySaveData()
            
        case let .waypoint(index):  // 중간 경유지를 지나가는 경우 음성 안내
            navigationManager.guideWithVoice(at: index)
            
        case .offroad:              // 경로에서 벗어난 경우, 현 위치에서 목적지 까지 새로운 경로를 구해 안내(Async)
            let warningAlert = UIAlertController(
                title: "경로 이탈",
                message: "경로를 재설정 합니다(3초 후 자동으로 사라집니다)",
                preferredStyle: .alert
            )
            warningAlert.addAction(UIAlertAction(title: "종료(저장)", style: .destructive){ _ in
                self.navigationManager.guideWithVoice(at: Int.max)
                
                self.isNavigationOn = false
                self.trySaveData()
            })
            warningAlert.addAction(UIAlertAction(title: "종료(취소)", style: .cancel){ _ in
                self.navigationManager.guideWithVoice(at: Int.max)
                
                self.isNavigationOn = false
            })
            self.present(warningAlert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                warningAlert.dismiss(animated: true, completion: nil)
            }
            
            navigationManager.guideWithVoice(at: Int.min)
            getRouteAndDrawForDestination(recorded: true)
            
        case .freeride:
            navigationManager.guideWithVoice(at: 0)
            break
        case .onroad:
            break
        case .error:
            break
        }
    }
    
    /// 주행기록 타이머 시작
    private func startTimer(selector: Selector) {
        recordTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: selector, userInfo: nil, repeats: true)
    }
    
    /// 주행기록 타이머 종료
    private func stopTimer() {
        
        recordTimer?.invalidate()
        recordTimer = nil
    }
    
    /// 주행 정보창 초기화
    private func initInfoView() {
        
        infoViewHeightConstraint.constant = 0
        infoView.isHidden = true
        
        timeLabel.text = "00:00:00"
        distanceLabel.text = nil
        calorieLabel.text = nil
        speedLabel.text = nil
        
        marqueeTitle.text = LiteralString.tracking.rawValue
    }
    
    /// 타이머를 통해 주행 정보 창 갱신
    @objc private func updateInfoView() {
        
        guard let speed = navigationManager.currentLocation?.speed else {
            return
        }
        
        timeLabel.text      = navigationManager.recordTime.digitalFormat
        distanceLabel.text  = "\((navigationManager.recordDistance / 1000.0).roundTo(places: 2))"
        calorieLabel.text   = "\(navigationManager.recordCalorie.roundTo(places: 1))"
        speedLabel.text     = speed < 0 ? "계산중" : "\(speed.roundTo(places: 1))"
    }
}


// MARK: Exteinsions

/// CoreLocation 네비게이션 작동 시에 사용
extension BiPeopleNavigationViewController: CLLocationManagerDelegate {
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        
        return false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        #if arch(i386) || arch(x86_64)
            return
        #else
            guard
                timeUnlocked < Date().timeIntervalSince1970,
                newHeading.timestamp.timeIntervalSinceNow > -30,
                newHeading.headingAccuracy >= 0
            else {
                return
            }
            
            navigationMapView.animate(toBearing: newHeading.trueHeading)
        #endif
    }
    
    /// 위치 변화 이벤트 핸들러
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let updatedLocation = locations.last else {
            print("Location is nil")
            return
        }
        
        // print("Updated Location: ", updatedLocation)    // FOR DEBUG
        
        if navigationManager.currentLocation == nil {
            
            navigationMapView.isHidden = false
            
            let seoul = CLLocationCoordinate2D(
                latitude: 37.541,
                longitude: 126.986
            )
            
            let worldCamera = GMSCameraPosition.camera(
                withTarget: seoul,
                zoom: 10
            )
            
            navigationMapView.camera = worldCamera

            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setValue(2, forKey: kCATransactionAnimationDuration)
                
                let camera = GMSCameraPosition.camera(
                    withTarget: updatedLocation.coordinate,
                    zoom: 15
                )
                self.navigationMapView.animate(to: camera)
                CATransaction.commit()
            }
            
            navigationMapView.setMinZoom(14, maxZoom: 100)
        }
        
        navigationManager.currentLocation = updatedLocation
        
        // 사용자의 사용이 없는 경우 맵의 중심을 현재 위치로
        if timeUnlocked < Date().timeIntervalSince1970 {
            moveMap(coordinate: updatedLocation.coordinate)
        }
        
        // 네비게이션 모드가 켜져있는 경우
        if isNavigationOn {
            
            // 상태 정보 창 토글
            toggleInfoView()
            
            // 위치 변화 정보 저장
            do {
                try navigationManager.addTrace(location: updatedLocation)
            } catch {
                print("Save trace data failed with error: ", error)
            }
            
            // 현재 위치를 NavigationBar Title로(Async)
            
            navigationManager.geoCoder(failure: { (error) in
                print("GeoCoder failed with error: ", error)
                self.marqueeTitle.text = LiteralString.tracking.rawValue
            }) { (address) in
                self.marqueeTitle.text = address
            }
            
            processBasedOnCurrentStatus()
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
        
        // FOR DEBUG
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
        placeDetailVC.nearPlaces = navigationManager.publicPlaces
        
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
        
        // 네비게이션 모드 중이 아닌 경우, 마커가 선택되어 Info Window가 보이고 있는 경우
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
        
        self.present(placePicker, animated: true)
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        
        pinScreen()
        
        return false
    }
}

/// 장소를 맵을 선택(터치)하여 선택해서
extension BiPeopleNavigationViewController: GMSPlacePickerViewControllerDelegate {
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        
        // FOR DEBUG
        print("Selected Place name: ", place.name)
        print("Selected Place address: ", place.formattedAddress ?? LiteralString.unknown.rawValue)
        print("Selected Place attributions: ", place.attributions ?? NSAttributedString())
        
        // Dismiss the place picker.
        viewController.dismiss(animated: true) {
            self.navigationManager.setDestination(
                coord: place.coordinate,
                name: place.name,
                address: place.formattedAddress
            )
            self.getRouteAndDrawForDestination()
        }
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didFailWithError error: Error) {

        // FOR DEBUG
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
        print("Searched Place address: ", place.formattedAddress ?? LiteralString.unknown.rawValue)
        print("Searched Place attributions: ", place.attributions ?? NSAttributedString())
        
        // 선택된 장소로 화면을 전환하기 위한 카메라 정보
        moveMap(coordinate: place.coordinate)
        
        navigationManager.setDestination(
            coord: place.coordinate,
            name: place.name,
            address: place.formattedAddress
        )
        getRouteAndDrawForDestination()
    }
    
    /// FOR DEBUG: 장소검색 자동완성에서 에러 발생 시
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        
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
