//
//  HistoryChartViewController.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

// TODO: 리펙토링 - 스위치 on off 별로 properties 세팅하기

import UIKit
import FSCalendar
import ScrollableGraphView

//MARK: enum

enum CalendarSwitch {
    case on, off
}

class HistoryChartViewController: UIViewController {
   
    //MARK: Properties
    
    @IBOutlet weak var graphView: ScrollableGraphView!
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    
    var startSwitch = CalendarSwitch.off
    var endSwitch = CalendarSwitch.off
    var numberOfItems = 30
    lazy var plotData: [Double] = generateRandomData(self.numberOfItems, max: 100, shouldIncludeOutliers: true)
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView.today = nil
        calendarView.isHidden = true
        
        graphView.dataSource = self
        setupGraph(graphView: graphView)
    }
    
    //MARK: Actions
    
    @IBAction func didTapStartLabel(_ sender: UITapGestureRecognizer) {
        if endSwitch == .on {
            self.calendarView.isHidden = false
            startSwitch = .on
            endSwitch = .off
            
            self.endLabel.textColor = .lightGray
            self.startLabel.textColor = .black
            
        }
        else {
            if self.calendarView.isHidden {
                startSwitch = .on
                endSwitch = .off
                self.endLabel.textColor = .lightGray
                self.startLabel.textColor = .black
            }
            else {
                startSwitch = .off
                endSwitch = .off
                self.endLabel.textColor = .black
                self.startLabel.textColor = .black
                
            }
            self.calendarView.isHidden = !self.calendarView.isHidden
        }
    }
    
    @IBAction func didTapEndLabel(_ sender: UITapGestureRecognizer) {
        if startSwitch == .on {
            self.calendarView.isHidden = false
            endSwitch = .on
            startSwitch = .off
            
            self.startLabel.textColor = .lightGray
            self.endLabel.textColor = .black
        }
        else {
            if self.calendarView.isHidden {
                endSwitch = .on
                startSwitch = .off
                self.endLabel.textColor = .black
                self.startLabel.textColor = .lightGray
            }
            else {
                endSwitch = .off
                startSwitch = .off
                self.startLabel.textColor = .black
                self.endLabel.textColor = .black
            }
            self.calendarView.isHidden = !self.calendarView.isHidden
        }
    }
    
}

//MARK: FSCalendarDelegate

extension HistoryChartViewController: FSCalendarDelegate {
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        // Do other updates here
        calendar.frame = CGRect(origin: calendar.frame.origin, size: bounds.size)
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if startSwitch == .on && endSwitch == .off {
            self.startLabel.text = date.toString()
        }
        else if startSwitch == .off && endSwitch == .on {
            self.endLabel.text = date.toString()
        }
        
        self.calendarView.isHidden = true
        self.startLabel.textColor = .black
        self.endLabel.textColor = .black
        
    }
    
}

//MARK: ScrollableGraphViewDataSource

extension HistoryChartViewController: ScrollableGraphViewDataSource {
    
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        switch(plot.identifier) {
        case "one":
            return plotData[pointIndex]
        default:
            return 0
        }
    }
    
    func label(atIndex pointIndex: Int) -> String {
        return "\(pointIndex)"
    }
    
    func numberOfPoints() -> Int {
        return numberOfItems
    }
    
    func setupGraph(graphView: ScrollableGraphView) {
        
        // Setup the first line plot.
        let linePlot = LinePlot(identifier: "one")
        
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
    
    private func generateRandomData(_ numberOfItems: Int, max: Double, shouldIncludeOutliers: Bool = true) -> [Double] {
        var data = [Double]()
        for _ in 0 ..< numberOfItems {
            var randomNumber = Double(arc4random()).truncatingRemainder(dividingBy: max)
            
            if(shouldIncludeOutliers) {
                if(randomNumber < 10) {
                    randomNumber *= 3
                }
            }
            
            print(randomNumber)
            
            data.append(randomNumber)
        }
        return data
    }
}
