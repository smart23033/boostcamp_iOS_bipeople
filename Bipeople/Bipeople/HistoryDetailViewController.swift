//
//  HistoryDetailViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import RealmSwift

class HistoryDetailViewController: UIViewController {
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ridingTimeLabel: UILabel!
    @IBOutlet weak var restTimeLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var highestSpeedLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    
    var record : Record?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        distanceLabel.text = "\(record?.distance ?? 0) km"
        ridingTimeLabel.text = "\(record?.ridingTime ?? 0)"
        restTimeLabel.text = "\(record?.restTime ?? 0)"
        averageSpeedLabel.text = "\(record?.averageSpeed ?? 0) km/h"
        highestSpeedLabel.text = "\(record?.highestSpeed ?? 0) km/h"
        caloriesLabel.text = "\(record?.calories ?? 0) kcal"
        createdAt.text = record?.createdAt.toString()
    }
    
}
