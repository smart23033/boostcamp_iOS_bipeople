//
//  HistoryGraphViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import RealmSwift
import FSCalendar
import ScrollableGraphView

//MARK: enum

enum CalendarSwitch {
    case on, off
}

enum GraphType {
    case distance
    case ridingTime
    case calories
    case maximumSpeed
    case averageSpeed
}

class HistoryGraphViewController: UIViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var prototypeGraphView: ScrollableGraphView!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var startLabel: UILabel! {
        didSet {
            startLabel.text = Date().toString()
        }
    }
    @IBOutlet weak var endLabel: UILabel! {
        didSet {
            endLabel.text = Date().toString()
        }
    }
    
    private var graphView: ScrollableGraphView?
    
    //MARK: Properties
    
    var startSwitch = CalendarSwitch.off {
        didSet {
            switch startSwitch {
            case .on:
                startLabel.textColor = .black
            case .off:
                startLabel.textColor = .lightGray
            }
        }
    }
    var endSwitch = CalendarSwitch.off {
        didSet {
            switch endSwitch {
            case .on:
                endLabel.textColor = .black
            case .off:
                endLabel.textColor = .lightGray
            }
        }
    }
    
    var records: [Record] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var requestedComponent: Set<Calendar.Component> = [.day]
    var numberOfItems = 0
    var distanceWithDate: [String:Double] = [:]
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prototypeGraphView.isHidden = true
        
        records = appDelegate.records
        
        self.calendarView.today = nil
        self.calendarView.isHidden = true
    }
    
    
    //MARK: Actions
    
    @IBAction func didChangeSegControl(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            requestedComponent = [.day]
        case 1:
            requestedComponent = [.weekOfMonth]
        case 2:
            requestedComponent = [.month]
        default:
            break
        }
    }
    
    @IBAction func didTapStartLabel(_ sender: UITapGestureRecognizer) {
        if endSwitch == .on {
            self.calendarView.isHidden = false
            startSwitch = .on
            endSwitch = .off
        }
        else {
            if self.calendarView.isHidden {
                startSwitch = .on
                endSwitch = .off
            }
            else {
                startSwitch = .off
                endSwitch = .off
                self.endLabel.textColor = .black
                self.startLabel.textColor = .black
                
            }
            self.calendarView.isHidden = !self.calendarView.isHidden
            self.graphView?.isHidden = !self.calendarView.isHidden
        }
    }
    
    @IBAction func didTapEndLabel(_ sender: UITapGestureRecognizer) {
        if startSwitch == .on {
            self.calendarView.isHidden = false
            endSwitch = .on
            startSwitch = .off
        }
        else {
            if self.calendarView.isHidden {
                endSwitch = .on
                startSwitch = .off
            }
            else {
                endSwitch = .off
                startSwitch = .off
                self.startLabel.textColor = .black
                self.endLabel.textColor = .black
            }
            
            self.calendarView.isHidden = !self.calendarView.isHidden
            self.graphView?.isHidden = !self.calendarView.isHidden
        }
    }
    
}

//MARK: FSCalendarDelegate

extension HistoryGraphViewController: FSCalendarDelegate {
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        // Do other updates here
        calendar.frame = CGRect(origin: calendar.frame.origin, size: bounds.size)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
       
        guard let frame = prototypeGraphView?.frame else {
            return
        }
        
        graphView?.removeFromSuperview()
        graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        guard let innerGraphView = graphView else {
            return
        }
    
        containerView.addSubview(innerGraphView)
        
        distanceWithDate = [:]
        
        //스위치가 켜지고 꺼짐에 따라 뷰가 다르게 보이는 부분
        if startSwitch == .on && endSwitch == .off {
            guard let limit = endLabel.text?.toDate() else {
                return
            }
            
            if date > limit {
                endLabel.text = date.toString()
            }
            self.startLabel.text = date.toString()
        }
        else if startSwitch == .off && endSwitch == .on {
            
            guard let limit = startLabel.text?.toDate() else {
                return
            }
            
            if date < limit {
                startLabel.text = date.toString()
            }
            self.endLabel.text = date.toString()
        }
        
        startSwitch = .off
        endSwitch = .off
        self.calendarView.isHidden = true
        self.graphView?.isHidden = !self.calendarView.isHidden
        self.startLabel.textColor = .black
        self.endLabel.textColor = .black
        
        guard let startDate = self.startLabel.text?.toDate(),
            let endDate = self.endLabel.text?.toDate()?.addingTimeInterval(24*60*60)
            else {
                return
        }
        
        //시간 차를 구하고 세그에 따라 numberOfItems를 결정하는 부분
        let timeDifference = Calendar.current.dateComponents(requestedComponent, from: startDate, to: endDate)
        
        print(timeDifference)
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            numberOfItems = timeDifference.day!
        case 1:
            numberOfItems = timeDifference.weekOfMonth!
        case 2:
            numberOfItems = timeDifference.month!
        default:
            break
        }
        
        //값을 가져오는 부분
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        records = Array(RealmHelper.fetchFromType(of: Record(), with: predicate))
        
        records.sort{ $0.createdAt < $1.createdAt }
        
        distanceWithDate = getDistanceData(startDate: startDate, endDate: endDate)
        
        print(records)
        print(distanceWithDate)
        
        setupGraph(graphView: innerGraphView)
    }
    
}

//MARK: ScrollableGraphViewDataSource

extension HistoryGraphViewController: ScrollableGraphViewDataSource {
    
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        let sortedDates = distanceWithDate.keys.sorted(by: <)
        
        switch(plot.identifier) {
        case "distance":
            
            guard pointIndex < sortedDates.count else {
                print("pointIndex: ", pointIndex)
                return 0
            }

            var distances = [Double]()
            
            for date in sortedDates {
                distanceWithDate.forEach({ (key,value) in
                    if key == date {
                        distances.append(value)
                    }
                })
            }
        
        return distances[pointIndex]
        
        default:
            return 0
        }
    }
    
    func label(atIndex pointIndex: Int) -> String {
        return "\(pointIndex)"
    }
    
    func numberOfPoints() -> Int {
        print("numberOfPoints: ", distanceWithDate.count)
        return distanceWithDate.count
    }
    
    //거리 데이터 구하기
    private func getDistanceData(startDate: Date, endDate: Date) -> [String:Double] {
        
        var data: [String:Double] = [:]
        
        guard records.count > 0 else {
            return [:]
        }
        
        for record in records {
            
            guard record.createdAt >= startDate,
                record.createdAt <= endDate else {
                    return [:]
            }
            
            let distance = record.distance
            
            if data[record.createdAt.toString()] != nil {
                data[record.createdAt.toString()]! += distance
            } else {
                data[record.createdAt.toString()] = distance
            }
            
        }
        
        return data
    }
    
    //MARK: setup graph
    
    func setupGraph(graphView: ScrollableGraphView) {
        
        // Setup the first line plot.
        let linePlot = LinePlot(identifier: "distance")
        
        linePlot.lineWidth = 5
        linePlot.lineColor = UIColor.primary
        linePlot.lineStyle = ScrollableGraphViewLineStyle.straight
        
        linePlot.shouldFill = false
        linePlot.fillType = ScrollableGraphViewFillType.solid
        linePlot.fillColor = UIColor.blue.withAlphaComponent(0.5)
        
        linePlot.adaptAnimationType = ScrollableGraphViewAnimationType.elastic
        
        // Customise the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = UIColor.black.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = UIColor.black
        
        referenceLines.dataPointLabelColor = UIColor.black.withAlphaComponent(1)
        
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: linePlot)
        
    }
    
}
