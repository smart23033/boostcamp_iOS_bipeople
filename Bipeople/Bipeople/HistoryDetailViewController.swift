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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        let records = Array(realm.objects(Record.self))
    
        distanceLabel.text = "\(records.first?.distance ?? 0)"
        ridingTimeLabel.text = "\(records.first?.ridingTime ?? 0)"
        restTimeLabel.text = "\(records.first?.restTime ?? 0)"
        averageSpeedLabel.text = "\(records.first?.averageSpeed ?? 0)"
        highestSpeedLabel.text = "\(records.first?.highestSpeed ?? 0)"
        caloriesLabel.text = "\(records.first?.calories ?? 0)"
        
    }
    
}
