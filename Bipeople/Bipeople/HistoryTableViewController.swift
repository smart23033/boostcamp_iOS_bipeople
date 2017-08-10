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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        RealmHelper.removeAllData()
        
        var record1 = Record()
        record1._id = Record.autoIncrement()
        record1.departure = "충무로"
        record1.arrival = "명동"
        record1.averageSpeed = 14.3
        record1.highestSpeed = 19.2
        record1.calories = 300.1
        record1.distance = 42.195
        record1.ridingTime = 13004
        record1.restTime = 100
        
        RealmHelper.addData(data: record1)
    }
    
}

extension HistoryTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        
        return cell
    }
}
