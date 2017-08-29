//
//  GraphViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import RealmSwift
import FSCalendar
//import ScrollableGraphView

//MARK: enum

enum CalendarSwitch {
    case on, off
}

enum GraphType: String {
    case distance = "거리"
    case ridingTime = "주행시간(분)"
    case calories = "칼로리"
    case averageSpeed = "평균속도"
}

enum Segments: Int {
    case day = 0
    case week
    case month
}

class GraphViewController: UIViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var filterLabel: UILabel! {
        didSet {
            filterLabel.text = selectedValue.rawValue
        }
    }
    @IBOutlet weak var startLabel: UILabel! {
        didSet {
            startLabel.text = Date().addingTimeInterval(-24*60*60*7).toString()
        }
    }
    @IBOutlet weak var endLabel: UILabel! {
        didSet {
            endLabel.text = Date().toString()
        }
    }
    
    @IBOutlet weak var distanceLabel: AnimatedLabel!
    @IBOutlet weak var averageSpeedLabel: AnimatedLabel!
    @IBOutlet weak var caloriesLabel: AnimatedLabel!
    
    @IBOutlet weak var hourLabel: AnimatedLabel! {
        didSet {
            hourLabel.decimalPoints = .zero
        }
    }
    @IBOutlet weak var minuteLabel: AnimatedLabel! {
        didSet {
            minuteLabel.decimalPoints = .zero
        }
    }
    @IBOutlet weak var secondLabel: AnimatedLabel! {
        didSet {
            secondLabel.decimalPoints = .zero
        }
    }
    
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
    
    // private var graphView: ScrollableGraphView?
    
    private var records: [Record] = []
    private var dataWithDate: [String:Double] = [:]
    
    private var pickerData: [GraphType] = [.distance,.ridingTime,.calories,.averageSpeed]
    private var selectedValue: GraphType = .distance
    
    private var distance: Double?
    private var ridingTime: TimeInterval?
    private var calories: Double?
    private var averageSpeed: Double?
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.calendarView.today = nil
        self.calendarView.isHidden = true
        
        reloadGraph()
        reloadDataSheet()        
    }
    
    //MARK: Functions
    
    func reloadGraph() {
        
        guard
            let startDate = self.startLabel.text?.toDate(),
            let endDate = self.endLabel.text?.toDate()?.addingTimeInterval(24 * 60 * 60 - 1)
        else {
            return
        }

        //값을 가져오는 부분
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        records = Array(RealmHelper.fetch(from: Record.self, with: predicate))

        records.sort{ $0.createdAt < $1.createdAt }

        switch selectedValue {
        case .distance:
            dataWithDate = getDataWithDate(type: .distance, startDate: startDate, endDate: endDate)
        case .ridingTime:
            dataWithDate = getDataWithDate(type: .ridingTime, startDate: startDate, endDate: endDate)
        case .calories:
            dataWithDate = getDataWithDate(type: .calories, startDate: startDate, endDate: endDate)
        case .averageSpeed:
            dataWithDate = getDataWithDate(type: .averageSpeed, startDate: startDate, endDate: endDate)
        }

        graphView.graphPoints = dataWithDate
    }
    
//    func reloadGraph2() {
//        guard let frame = graphView?.frame else {
//            return
//        }
//
//        graphView?.removeFromSuperview()
//        graphView = ScrollableGraphView(frame: frame, dataSource: self)
//
//        guard let innerGraphView = graphView else {
//            return
//        }
//
//        containerView.addSubview(innerGraphView)
//
//        guard let startDate = self.startLabel.text?.toDate(),
//            let endDate = self.endLabel.text?.toDate()?.addingTimeInterval(24*60*60)
//            else {
//                return
//        }
//
//        //값을 가져오는 부분
//        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
//        records = Array(RealmHelper.fetch(from: Record.self, with: predicate))
//
//        records.sort{ $0.createdAt < $1.createdAt }
//
//        switch selectedValue {
//        case .distance:
//            dataWithDate = getDataWithDate(type: .distance, startDate: startDate, endDate: endDate)
//        case .ridingTime:
//            dataWithDate = getDataWithDate(type: .ridingTime, startDate: startDate, endDate: endDate)
//        case .calories:
//            dataWithDate = getDataWithDate(type: .calories, startDate: startDate, endDate: endDate)
//        case .averageSpeed:
//            dataWithDate = getDataWithDate(type: .averageSpeed, startDate: startDate, endDate: endDate)
//        }
//
//        guard let maxValue = dataWithDate.values.sorted(by: >).first else {
//            return
//        }
//
//        setupGraph(graphView: innerGraphView, max: maxValue)
//    }
    
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
        
        //        let days = self.ridingTime?.days
        let hours = self.ridingTime?.hours
        let minutes = self.ridingTime?.minutes
        let seconds = self.ridingTime?.seconds
        
        self.distanceLabel.count(to: Float(self.distance ?? 0))
        self.averageSpeedLabel.count(to: Float(self.averageSpeed ?? 0))
        self.caloriesLabel.count(to: Float(self.calories ?? 0))
        
        self.hourLabel.count(to: Float(hours ?? 0))
        self.minuteLabel.count(to: Float(minutes ?? 0))
        self.secondLabel.count(to: Float(seconds ?? 0))
        
    }
    
    //날짜별 데이터 획득
    func getDataWithDate(type: GraphType, startDate: Date, endDate: Date) -> [String:Double] {
        
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
                data = record.ridingTime.minutesForGraph
            case .calories:
                data = record.calories
            case .averageSpeed:
                data = record.averageSpeed
            }
            
            //세그먼트 컨트롤에 따라 누적값 설정부분
            let selectedSegment = Segments(rawValue: segmentedControl.selectedSegmentIndex)!
            
            var countForAverageSpeed = 1.0
            
            switch selectedSegment {
            case .day:
                if datas[record.createdAt.toString()] != nil {
                    datas[record.createdAt.toString()]! += data
                    countForAverageSpeed += 1
                } else {
                    datas[record.createdAt.toString()] = data
                }
                
                if type == .averageSpeed {
                    datas[record.createdAt.toString()]! /= countForAverageSpeed
                }
                
            case .week:
                
                guard var startDateOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: records[0].createdAt)?.start else {
                    return [:]
                }
                
                //첫주 데이터 넣으려고 넣은 한줄
                datas[startDateOfWeek.toString()] = data
                
                
                if startDateOfWeek == Calendar.current.dateInterval(of: .weekOfYear, for: record.createdAt)?.start {
                    datas[startDateOfWeek.toString()]! += data
                    countForAverageSpeed += 1
                }
                else {
                    startDateOfWeek = (Calendar.current.dateInterval(of: .weekOfYear, for: record.createdAt)?.start)!
                    datas[startDateOfWeek.toString()] = data
                }
                
                if type == .averageSpeed {
                    datas[startDateOfWeek.toString()]! /= countForAverageSpeed
                }
                
                
            case .month:
                guard var startDateOfMonth = Calendar.current.dateInterval(of: .month, for: records[0].createdAt)?.start else {
                    return [:]
                }
                
                //첫달 데이터넣으려고
                datas[startDateOfMonth.toString()] = data
                
                if startDateOfMonth == Calendar.current.dateInterval(of: .month, for: record.createdAt)?.start {
                    datas[startDateOfMonth.toString()]! += data
                    countForAverageSpeed += 1
                }
                else {
                    startDateOfMonth = (Calendar.current.dateInterval(of: .month, for: record.createdAt)?.start)!
                    datas[startDateOfMonth.toString()] = data
                }
                
                if type == .averageSpeed {
                    datas[startDateOfMonth.toString()]! /= countForAverageSpeed
                }
                
            }
        }
        
        return datas
    }
    
    //MARK: Actions
    
    @IBAction func didChangeSegControl(_ sender: UISegmentedControl) {
        reloadGraph()
    }
    
    @IBAction func didTapFilterLabel(_ sender: UITapGestureRecognizer) {
        let alertView = UIAlertController(
            title: "원하는 정렬을 선택하세요",
            message: "\n\n\n\n\n\n\n",
            preferredStyle: .actionSheet)
        
        
        let pickerView = UIPickerView(frame:
            CGRect(x: 0, y: 50, width: self.view.bounds.width, height: 130))
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        alertView.view.addSubview(pickerView)
        
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { _ in
            
            self.filterLabel.text = self.selectedValue.rawValue
            
            self.reloadGraph()
            self.reloadDataSheet()
        })
        
        alertView.addAction(action)
        
        present(alertView, animated: true, completion: { () -> Void in
            pickerView.frame.size.width = alertView.view.frame.size.width
            
            self.selectedValue = .distance
            
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

extension GraphViewController: FSCalendarDelegate {
    
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

//extension GraphViewController: ScrollableGraphViewDataSource {
//
//
//    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
//
//        let sortedDates = dataWithDate.keys.sorted(by: <)
//
//        switch(plot.identifier) {
//        case "plot":
//
//            guard pointIndex < sortedDates.count else {
//                return 0
//            }
//
//            var distances = [Double]()
//
//            for date in sortedDates {
//                dataWithDate.forEach({ (key,value) in
//                    if key == date {
//                        distances.append(value)
//                    }
//                })
//            }
//
//            return distances[pointIndex]
//
//        default:
//            return 0
//        }
//    }
//
//    func label(atIndex pointIndex: Int) -> String {
//        let sortedDates = dataWithDate.keys.sorted(by: <)
//
//        return "\(sortedDates[pointIndex])"
//    }
//
//    func numberOfPoints() -> Int {
//        //        print("numberOfPoints: ", dataWithDate.count)
//        return dataWithDate.count
//    }
//
//    func setupGraph(graphView: ScrollableGraphView, max: Double) {
//
//        // Setup the first line plot.
//        let linePlot = LinePlot(identifier: "plot")
//
//        linePlot.lineWidth = 2
//        linePlot.lineColor = UIColor.primary
//        linePlot.lineStyle = ScrollableGraphViewLineStyle.straight
//
//        linePlot.shouldFill = true
//        linePlot.fillType = ScrollableGraphViewFillType.solid
//        linePlot.fillColor = UIColor.primary.withAlphaComponent(0.2)
//
//        linePlot.adaptAnimationType = ScrollableGraphViewAnimationType.elastic
//
//        // Customise the reference lines.
//        let referenceLines = ReferenceLines()
//
//        referenceLines.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
//        referenceLines.referenceLineColor = UIColor.black.withAlphaComponent(0.2)
//        referenceLines.referenceLineLabelColor = UIColor.black
//        referenceLines.dataPointLabelColor = UIColor.black.withAlphaComponent(1)
//
//
//        graphView.addReferenceLines(referenceLines: referenceLines)
//        graphView.addPlot(plot: linePlot)
//
//        graphView.rangeMax = max
//        graphView.dataPointSpacing = 70
//
//    }
//}

//MARK: UIPickerViewDelegate

extension GraphViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
        selectedValue = pickerData[pickerView.selectedRow(inComponent: 0)]
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 35
    }
}
