//
//  HistoryTableViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import RealmSwift

class HistoryTableViewController: UIViewController {
    
    var records: [Record]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
//        RealmHelper.removeAllData()
        
        // 데이터 배열로 넣어보기 진행 중!
//        for i in 0..<20 {
//            var record = Record()
//            record._id = Record.autoIncrement()
//            record.departure = "start \(i)"
//            record.arrival = "end \(i)"
//            record.averageSpeed = Double(arc4random_uniform(1000)) / Double(10)
//            record.highestSpeed = Double(arc4random_uniform(1000)) / Double(10)
//            record.calories = 300.1
//            record.distance = Double(arc4random_uniform(1000)) / Double(10)
//            record.ridingTime = 13004
//            record.restTime = 100
            
//            let record = Record(departure: "start \(i)",
//                arrival: "end \(i)",
//                distance: Double(arc4random_uniform(1000)) / Double(10),
//                ridingTime: Double(arc4random_uniform(1000)) / Double(10),
//                restTime: Double(arc4random_uniform(1000)) / Double(10),
//                averageSpeed:Double(arc4random_uniform(1000)) / Double(10),
//                highestSpeed: Double(arc4random_uniform(1000)) / Double(10),
//                calories: Double(arc4random_uniform(1000)) / Double(10))
//
//            RealmHelper.addData(data: record)
//        }
    }
    
}

extension HistoryTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = records?.count{
            return count
        } else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
     
        return cell
    }
}
