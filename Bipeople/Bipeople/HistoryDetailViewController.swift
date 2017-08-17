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
        
        guard let recordID = record?._id  else {
            return
        }
        
//        let predicate = NSPredicate(format: "recordID = %@", recordID)
//        traces = Array(RealmHelper.fetchFromType(of: Trace(), with: predicate))
        
        titleLabel.title = "\(record?.departure ?? "unknown") - \(record?.arrival ?? "unknown")"
        distanceLabel.text = "\(record?.distance ?? 0) km"
        ridingTimeLabel.text = record?.ridingTime.stringTime
        restTimeLabel.text = "\(record?.restTime ?? 0)"
        averageSpeedLabel.text = "\(record?.averageSpeed ?? 0) m/s"
        maximumSpeedLabel.text = "\(record?.maximumSpeed ?? 0) m/s"
        caloriesLabel.text = "\(record?.calories ?? 0) kcal"
        createdAt.text = record?.createdAt.toString()
        
    }
    
    //MARK: Functions
    
    func drawRoute(from data: GeoJSON) {
        let navigationPath = GMSMutablePath()
        
        traces?.forEach({ (trace) in
            navigationPath.add(CLLocationCoordinate2D(latitude: trace.latitude, longitude: trace.longitude))
        })
        
        navigationRoute = GMSPolyline(path: navigationPath)
        
        guard let route = navigationRoute else {
            return
        }
        
        route.strokeWidth = 5
        route.strokeColor = UIColor.primary
        
        DispatchQueue.main.async {
            route.map = self.mapView
        }
    }
    
}
