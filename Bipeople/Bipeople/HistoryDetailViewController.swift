//
//  HistoryDetailViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps

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
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let recordID = record?._id else {
            return
        }
        
        let predicate = NSPredicate(format: "recordID = %d", recordID)
        traces = Array(RealmHelper.fetch(from: Trace.self, with: predicate))
        
        titleLabel.title = "\(record?.departure ?? "unknown") - \(record?.arrival ?? "unknown")"
        distanceLabel.text = "\(record?.distance.roundTo(places: 1) ?? 0) km"
        ridingTimeLabel.text = record?.ridingTime.stringTime
        restTimeLabel.text = "\(record?.restTime ?? 0)"
        averageSpeedLabel.text = "\(record?.averageSpeed.roundTo(places: 1) ?? 0) m/s"
        maximumSpeedLabel.text = "\(record?.maximumSpeed.roundTo(places: 1) ?? 0) m/s"
        caloriesLabel.text = "\(record?.calories.roundTo(places: 1) ?? 0) kcal"
        createdAt.text = record?.createdAt.toString()
        
        drawRoute()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let firstTrace = traces?.first,
        let lastTrace = traces?.last,
            let traceCount = traces?.count,
            let middleTrace = traces?[traceCount/2]
            else {
            return
        }
        
        let camera = GMSCameraPosition.camera(
            withLatitude: middleTrace.latitude,
            longitude: middleTrace.longitude,
            zoom: 13
        )
        
        mapView.camera = camera
    }
    
    //MARK: Functions
    
    func drawRoute() {
        let navigationPath = GMSMutablePath()
        
        traces?.forEach({ (trace) in
            navigationPath.add(CLLocationCoordinate2D(latitude: trace.latitude, longitude: trace.longitude))
        })
        
        navigationRoute = GMSPolyline(path: navigationPath)
        
        guard let route = navigationRoute else {
            return
        }
        
        route.map = nil
        route.strokeWidth = 5
        route.strokeColor = UIColor.primary
        
        DispatchQueue.main.async {
            route.map = self.mapView
        }
    }
    
}
