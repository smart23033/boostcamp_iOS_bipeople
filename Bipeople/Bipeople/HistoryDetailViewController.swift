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
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ridingTimeLabel: UILabel!
    @IBOutlet weak var restTimeLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var maximumSpeedLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    
    var record : Record?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        titleLabel.title = "\(record?.departure ?? "unknown") - \(record?.arrival ?? "unknown")"
        distanceLabel.text = "\(record?.distance ?? 0) km"
        ridingTimeLabel.text = "\(record?.ridingTime ?? 0)"
        restTimeLabel.text = "\(record?.restTime ?? 0)"
        averageSpeedLabel.text = "\(record?.averageSpeed ?? 0) km/h"
        maximumSpeedLabel.text = "\(record?.maximumSpeed ?? 0) km/h"
        caloriesLabel.text = "\(record?.calories ?? 0) kcal"
        createdAt.text = record?.createdAt.toString()
        
    }
    
}
