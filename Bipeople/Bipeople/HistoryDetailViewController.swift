//
//  HistoryDetailViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps
import MarqueeLabel

enum PolyLineType: String {
    case altitude = "고도"
    case speed = "속도"
}

class HistoryDetailViewController: UIViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ridingTimeLabel: UILabel!
    @IBOutlet weak var restTimeLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var maximumSpeedLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var filterLabel: UILabel! {
        didSet {
            filterLabel.text = selectedValue.rawValue
        }
    }
    
    //MARK: Properties
    
    var record: Record?
    var traces: [Trace]?
    var navigationRoute: GMSPolyline?
    var marqueeTitle : MarqueeLabel?
    
    var redValue = Double()
    var greenValue = Double()
    var maxAltitude = Double()
    var maxSpeed = Double()
    
    var pickerData: [PolyLineType] = [.altitude,.speed]
    var selectedValue: PolyLineType = .altitude
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let recordID = record?._id else {
            return
        }
        
        marqueeTitle = MarqueeLabel()
        
        let predicate = NSPredicate(format: "recordID = %d", recordID)
        traces = Array(RealmHelper.fetch(from: Trace.self, with: predicate))
        
        marqueeTitle?.text = "\(record?.departure ?? "unknown") - \(record?.arrival ?? "unknown")"
        marqueeTitle?.textColor = UIColor.white
        titleLabel.titleView = marqueeTitle
        distanceLabel.text = "\(record?.distance.roundTo(places: 1) ?? 0) km"
        ridingTimeLabel.text = record?.ridingTime.stringTime
        restTimeLabel.text = record?.restTime.stringTime
        averageSpeedLabel.text = "\(record?.averageSpeed.roundTo(places: 1) ?? 0) m/s"
        maximumSpeedLabel.text = "\(record?.maximumSpeed.roundTo(places: 1) ?? 0) m/s"
        caloriesLabel.text = "\(record?.calories.roundTo(places: 1) ?? 0) kcal"
        createdAt.text = record?.createdAt.toString()
        
        drawRoute(type: PolyLineType.altitude)
        
    }
    
    //MARK: Actions
    
    @IBAction func didTapFilterLabel(_ sender: UITapGestureRecognizer) {
        
        let alertView = UIAlertController(
            title: "Select item from list",
            message: "\n\n\n\n\n\n\n",
            preferredStyle: .actionSheet)
        
        
        let pickerView = UIPickerView(frame:
            CGRect(x: 0, y: 50, width: self.view.bounds.width, height: 130))
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        alertView.view.addSubview(pickerView)
        
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        
        alertView.addAction(action)
        
        present(alertView, animated: true, completion: { () -> Void in
            pickerView.frame.size.width = alertView.view.frame.size.width

            self.selectedValue = self.pickerData[pickerView.selectedRow(inComponent: 0)]
            self.filterLabel.text = self.selectedValue.rawValue
            
        })
        
    }
    
    
    //MARK: Functions
    
    func drawRoute(type: PolyLineType) {
        mapView.clear()
        
        var colorsAtCoordinate = [UIColor]()
        let navigationPath = GMSMutablePath()
  
        //패스 설정 및 최대 고도 구함
        traces?.forEach({ (trace) in
            navigationPath.add(CLLocationCoordinate2D(latitude: trace.latitude, longitude: trace.longitude))
            
            switch type {
                
            case .speed:
                if trace.speed > maxSpeed {
                    maxSpeed = trace.speed
                }
            case .altitude:
                if trace.altitude > maxAltitude {
                    maxAltitude = trace.altitude
                }
            }
            
        })
        
        // red = (현재고도/최대고도), green = 1.0 - red
        traces?.forEach({ (trace) in
            
            switch type {
            case .speed:
                if maxSpeed == 0 {
                    redValue = 0.0
                }
                else {
                    redValue = (trace.speed / maxSpeed)
                }
            case .altitude:
                if maxAltitude == 0 {
                    redValue = 0.0
                }
                else {
                    redValue = (trace.altitude / maxAltitude)
                }
            }
            
            greenValue = 1.0 - redValue
            
            colorsAtCoordinate.append(UIColor(red: CGFloat(redValue), green: CGFloat(greenValue), blue: 0, alpha: 1.0))
        })
        
        navigationRoute = GMSPolyline(path: navigationPath)
        
        var currentColor = UIColor()
        var spans = [GMSStyleSpan]()
        var isFirstIndex = true
        
        colorsAtCoordinate.forEach { (color) in
            
            guard !isFirstIndex else {
                currentColor = color
                isFirstIndex = !isFirstIndex
                return
            }
            
            spans.append(GMSStyleSpan(style: GMSStrokeStyle.gradient(from: currentColor, to: color)))
            
            currentColor = color
        }
        
        //경로 생성
        guard let route = navigationRoute else {
            return
        }
        
        route.strokeWidth = 5
        //        route.strokeColor = UIColor.primary
        route.spans = spans
        
        DispatchQueue.main.async {
            route.map = self.mapView
        }
        
        //카메라 설정
        guard let firstTrace = traces?.first,
            let traceCount = traces?.count,
            let middleTrace = traces?[traceCount/2],
            let lastTrace = traces?.last else {
                return
                
        }
        
        mapView.camera = GMSCameraPosition.camera(
            withLatitude: middleTrace.latitude,
            longitude: middleTrace.longitude,
            zoom: 13
        )
        
        //출발 마커 생성
        let departureMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: firstTrace.latitude, longitude: firstTrace.longitude))
        let departureIconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let departureIcon = UIImage(named: "departure")
        departureIconView.image = departureIcon
        departureMarker.iconView = departureIconView
        departureMarker.map = mapView
        
        //도착 마커 생성
        let arrivalMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: lastTrace.latitude, longitude: lastTrace.longitude))
        let arrivalIconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let arrivalIcon = UIImage(named: "arrival")
        arrivalIconView.image = arrivalIcon
        arrivalMarker.iconView = arrivalIconView
        arrivalMarker.map = mapView
        
    }
    
}

//MARK: UIPickerViewDelegate

extension HistoryDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        selectedValue = pickerData[pickerView.selectedRow(inComponent: 0)]
        filterLabel.text = selectedValue.rawValue
        
        self.drawRoute(type: selectedValue)
        
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }
}
