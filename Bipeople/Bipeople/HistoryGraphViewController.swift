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

enum GraphType: String {
    case distance = "거리"
    case ridingTime = "주행시간"
    case calories = "칼로리"
    case maximumSpeed = "최고속도"
    case averageSpeed = "평균속도"
}

enum Segments: Int {
    case day = 0
    case week
    case month
}

class HistoryGraphViewController: UIViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var prototypeGraphView: ScrollableGraphView!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var filterLabel: UILabel!
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
    
    @IBOutlet weak var distanceLabel: AnimatedLabel!
    @IBOutlet weak var ridingTimeLabel: AnimatedLabel!
    @IBOutlet weak var averageSpeedLabel: AnimatedLabel!
    @IBOutlet weak var caloriesLabel: AnimatedLabel!
    
    
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
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var records: [Record] = []
    
    private var graphView: ScrollableGraphView?
    var dataWithDate: [String:Double] = [:]
    
    var pickerData: [GraphType] = [.distance,.ridingTime,.calories]
    var selectedValue: String = ""
    
    var distance: Double?
    var ridingTime: TimeInterval?
    var calories: Double?
    var averageSpeed: Double?
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        records = appDelegate.records
        
        self.calendarView.today = nil
        self.calendarView.isHidden = true
    }
    
    //MARK: Functions
    
    func reloadGraph() {
        guard let frame = prototypeGraphView?.frame else {
            return
        }
        
        graphView?.removeFromSuperview()
        graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        guard let innerGraphView = graphView else {
            return
        }
        
        containerView.addSubview(innerGraphView)
        
        guard let startDate = self.startLabel.text?.toDate(),
            let endDate = self.endLabel.text?.toDate()?.addingTimeInterval(24*60*60)
            else {
                return
        }
        
        //값을 가져오는 부분
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        records = Array(RealmHelper.fetchFromType(of: Record(), with: predicate))
        
        records.sort{ $0.createdAt < $1.createdAt }
        
        switch selectedValue {
        case GraphType.distance.rawValue:
            dataWithDate = getDataWithDate(type: .distance, startDate: startDate, endDate: endDate)
        case GraphType.ridingTime.rawValue:
            dataWithDate = getDataWithDate(type: .ridingTime, startDate: startDate, endDate: endDate)
        case GraphType.calories.rawValue:
            dataWithDate = getDataWithDate(type: .calories, startDate: startDate, endDate: endDate)
        default:
            break
        }
        
        guard let maxValue = dataWithDate.values.sorted(by: >).first else {
            return
        }
        
        setupGraph(graphView: innerGraphView, max: maxValue)
        
    }
    
    func reloadDataSheet() {
        
        self.distance = 0
        self.ridingTime = 0
        self.averageSpeed = 0
        self.calories = 0
        
        guard let startDate = self.startLabel.text?.toDate(),
            let endDate = self.endLabel.text?.toDate()?.addingTimeInterval(24*60*60)
            else {
                return
        }
        
        for record in records {
            
            guard record.createdAt >= startDate,
                record.createdAt <= endDate else {
                    return
            }
            
            self.distance! += record.distance
            self.ridingTime! += record.ridingTime
            self.averageSpeed! += record.averageSpeed
            self.calories! += record.calories
        }
        
        self.averageSpeed = self.averageSpeed! / Double(records.count)
        
        self.distanceLabel.countFromZero(to: Float(self.distance ?? 0))
        self.ridingTimeLabel.countFromZero(to: Float(self.ridingTime ?? 0))
        self.averageSpeedLabel.countFromZero(to: Float(self.averageSpeed ?? 0))
        self.caloriesLabel.countFromZero(to: Float(self.calories ?? 0))
        
    }
    
    //MARK: Actions
    
    @IBAction func didChangeSegControl(_ sender: UISegmentedControl) {
        
        reloadGraph()
        reloadDataSheet()
        
    }
    @IBAction func didTapFilterLabel(_ sender: UITapGestureRecognizer) {
        let alertView = UIAlertController(
            title: "Select item from list",
            message: "\n\n\n\n\n\n\n",
            preferredStyle: .actionSheet)
        
        let pickerView = UIPickerView(frame:
            CGRect(x: 0, y: 50, width: self.view.bounds.width, height: 130))
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        alertView.view.addSubview(pickerView)
        
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        
        alertView.addAction(action)
        present(alertView, animated: true, completion: { () -> Void in
            pickerView.frame.size.width = alertView.view.frame.size.width
        })
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
        
        reloadGraph()
        reloadDataSheet()
        
    }
    
}

//MARK: ScrollableGraphViewDataSource

extension HistoryGraphViewController: ScrollableGraphViewDataSource {
    
    
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        
        let sortedDates = dataWithDate.keys.sorted(by: <)
        
        switch(plot.identifier) {
        case "distance":
            
            guard pointIndex < sortedDates.count else {
                print("pointIndex: ", pointIndex)
                return 0
            }
            
            var distances = [Double]()
            
            for date in sortedDates {
                dataWithDate.forEach({ (key,value) in
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
        let sortedDates = dataWithDate.keys.sorted(by: <)
        
        return "\(sortedDates[pointIndex])"
    }
    
    func numberOfPoints() -> Int {
        //        print("numberOfPoints: ", dataWithDate.count)
        return dataWithDate.count
    }
    
    //날짜별 데이터 획득
    private func getDataWithDate(type: GraphType ,startDate: Date, endDate: Date) -> [String:Double] {
        
        var datas: [String:Double] = [:]
        var data = Double()
        
        guard records.count > 0 else {
            return [:]
        }
        
        for record in records {
            
            guard record.createdAt >= startDate,
                record.createdAt <= endDate else {
                    return [:]
            }
            
            //타입에 따라 데이터의 타입 결정
            switch type {
            case .distance:
                data = record.distance
            case .ridingTime:
                data = record.ridingTime
            case .calories:
                data = record.calories
            default: break
            }
            
            //세그먼트 컨트롤에 따라 누적값 설정부분
            let selectedSegment = Segments(rawValue: segmentedControl.selectedSegmentIndex)!
            
            switch selectedSegment {
            case .day:
                if datas[record.createdAt.toString()] != nil {
                    datas[record.createdAt.toString()]! += data
                } else {
                    datas[record.createdAt.toString()] = data
                }
            case .week:
                guard var startDateOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: records[0].createdAt)?.start else {
                    return [:]
                }
                datas[startDateOfWeek.toString()] = data
                
                records.forEach { (record) in
                    if startDateOfWeek == Calendar.current.dateInterval(of: .weekOfYear, for: record.createdAt)?.start {
                        datas[startDateOfWeek.toString()]! += data
                    }
                    else {
                        startDateOfWeek = (Calendar.current.dateInterval(of: .weekOfYear, for: record.createdAt)?.start)!
                        datas[startDateOfWeek.toString()] = data
                    }
                }
            case .month:
                guard var startDateOfMonth = Calendar.current.dateInterval(of: .month, for: records[0].createdAt)?.start else {
                    return [:]
                }
                datas[startDateOfMonth.toString()] = data
                
                records.forEach { (record) in
                    if startDateOfMonth == Calendar.current.dateInterval(of: .month, for: record.createdAt)?.start {
                        datas[startDateOfMonth.toString()]! += data
                    }
                    else {
                        startDateOfMonth = (Calendar.current.dateInterval(of: .month, for: record.createdAt)?.start)!
                        datas[startDateOfMonth.toString()] = data
                    }
                }
            }
        }
        
        return datas
    }
    
    //MARK: setup graph
    
    func setupGraph(graphView: ScrollableGraphView, max: Double) {
        
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
        
        graphView.rangeMax = max
        graphView.dataPointSpacing = 70
        
    }
}

extension HistoryGraphViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        selectedValue = pickerData[pickerView.selectedRow(inComponent: 0)].rawValue
        filterLabel.text = selectedValue
        
        reloadGraph()
        reloadDataSheet()
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }
}
