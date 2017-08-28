//
//  HistoryTableViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import RealmSwift

class HistoryTableViewController: UIViewController {
    
    //MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    var records: [Record] = []
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let realm = try! Realm()
        records = realm.objects(Record.self).sorted{ $0.createdAt > $1.createdAt }
        
        tableView.reloadData()
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "HistoryDetail" {
            
            guard
                let historyDetailVC = segue.destination as? HistoryDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow,
                indexPath.row < records.count
            else {
                return
            }

            historyDetailVC.record = records[indexPath.row]
        }
    }
    
}

//MARK: UITableViewDelegate

extension HistoryTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
        
        guard indexPath.row < records.count else {
            return cell
        }
        
        let record = records[indexPath.row]
        
        cell.titleLabel?.text = "\(record.departure) - \(record.arrival)"
        cell.distanceLabel?.text = "\(record.distance.roundTo(places: 1)) km"
        cell.dateLabel?.text = record.createdAt.toString()
        
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard indexPath.row < records.count else {
            return
        }
        
        let record = records[indexPath.row]
        
        if case .delete = editingStyle {
            
            let predicate = NSPredicate(format: "recordID = %d", record._id)
            RealmHelper.delete(data: Trace.self, with: predicate)
          
            records.remove(at: indexPath.row)
            RealmHelper.delete(data: record)
            
//          tableView.deleteRows(at: [indexPath], with: .fade) // FIXME: 가끔 삭제시 Crash 발생
            tableView.reloadData()
        }
    }
    
}
