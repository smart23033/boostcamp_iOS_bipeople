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
    
    //MARK: Properties
    
    var record: Record?
    var traces: [Trace]?
    var navigationRoute: GMSPolyline?
    var marqueeTitle : MarqueeLabel?
    
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
        restTimeLabel.text = "\(record?.restTime ?? 0)"
        averageSpeedLabel.text = "\(record?.averageSpeed.roundTo(places: 1) ?? 0) m/s"
        maximumSpeedLabel.text = "\(record?.maximumSpeed.roundTo(places: 1) ?? 0) m/s"
        caloriesLabel.text = "\(record?.calories.roundTo(places: 1) ?? 0) kcal"
        createdAt.text = record?.createdAt.toString()
        
        drawRoute()
    }
    
    //MARK: Functions
    
    func drawRoute() {
        let navigationPath = GMSMutablePath()
        
        traces?.forEach({ (trace) in
            navigationPath.add(CLLocationCoordinate2D(latitude: trace.latitude, longitude: trace.longitude))
        })
        
        navigationRoute = GMSPolyline(path: navigationPath)
        
        guard let route = navigationRoute,
            let firstTrace = traces?.first,
            let traceCount = traces?.count,
            let middleTrace = traces?[traceCount/2],
            let lastTrace = traces?.last else {
                return
        }
        
        //경로 생성
        route.map = nil
        route.strokeWidth = 5
        route.strokeColor = UIColor.primary
        
        DispatchQueue.main.async {
            route.map = self.mapView
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

