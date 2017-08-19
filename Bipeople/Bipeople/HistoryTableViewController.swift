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
    
    //MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    var records: [Record]?
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let realm = try! Realm()
        records = realm.objects(Record.self).sorted{ $0.createdAt < $1.createdAt }
        
        tableView.reloadData()
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HistoryDetail" {
            guard let historyDetailViewController = segue.destination as? HistoryDetailViewController,
                let indexPath = tableView.indexPathForSelectedRow else {
                return
            }

            historyDetailViewController.record = records?[indexPath.row]
        }
    }
    
}

//MARK: UITableViewDelegate

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
        
        cell.titleLabel?.text = "\(records?[indexPath.row].departure ?? "unknown") - \(records?[indexPath.row].arrival ?? "unknown")"
        cell.distanceLabel?.text = "\(records?[indexPath.row].distance.roundTo(places: 1) ?? 0) km"
        cell.dateLabel?.text = records?[indexPath.row].createdAt.toString()
        
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if case .delete = editingStyle {
            RealmHelper.delete(data: records![indexPath.row])
            records?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
