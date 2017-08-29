//
//  GraphView.swift
//  GraphView
//
//  Created by CONNECT on 2017. 8. 29..
//  Copyright © 2017년 CONNECT. All rights reserved.
//

import UIKit

class GraphView: UIScrollView {
    
    //1 - the properties for the gradient
    @IBInspectable var startColor: UIColor = UIColor(
        red: 250.0 / 255.0,
        green: 233.0 / 255.0,
        blue: 222.0 / 255.0,
        alpha: 1.0
    )
    
    @IBInspectable var endColor: UIColor = UIColor(
        red: 252.0 / 255.0,
        green: 79.0 / 255.0,
        blue: 8.0 / 255.0,
        alpha: 1.0
    )
    
    @IBInspectable var numOfPointsShowed: Int = 5 {
        willSet(newVal) {
            self.numOfPointsShowed = newVal < 1 ? 1 : newVal
        }
    }
    
    @IBInspectable var margin: CGFloat = 10
    @IBInspectable var topBorder: CGFloat = 10
    @IBInspectable var bottomBorder: CGFloat = 20
    @IBInspectable var labelSize: CGFloat = 30
    
    public var graphPoints:[String:Double] = [
        "2017-08-20": 0,
        "2017-08-29": 1.5,
        "2017-08-21": 3,
        "2017-08-28": 4.5,
        "2017-08-22": 6,
        "2017-08-27": 7.5,
        "2017-08-23": 9,
        "2017-08-26": 10.5,
        "2017-08-24": 12,
        "2017-08-25": 13.5,
        "2017-08-31": 15,
        "2017-08-19": 16.5,
        "2017-08-17": 18,
        "2017-08-18": 19.5
        ] {
        didSet {
            setContents()
        }
    }
    
    private var isInstalled: Bool = true
    
    private var effectiveWidth: CGFloat!
    
    private var intervalWidth: CGFloat!
    
    private var beginX: Int = 0
    
    private var endX: Int = 0
    
    private var referenceLinePath: UIBezierPath?
    
    private var xLabels:[UILabel] = []
    
    private var yLabels:[UILabel] = []
    
    private var needXLabelUpdated: Bool = true
    
    private var needYLabelUpdated: Bool = true
    
    private func setContents() {
        
        var width: CGFloat
        
        effectiveWidth = self.frame.width - (margin * 2)
        
        intervalWidth = effectiveWidth / CGFloat(numOfPointsShowed)
        
        if graphPoints.count < numOfPointsShowed {
            width = self.frame.width
        } else {
            width = CGFloat(graphPoints.count) * intervalWidth
            width += intervalWidth
        }
        
        self.contentSize = CGSize(width: width, height : 0)
        
        beginX = 0
        
        endX = beginX + numOfPointsShowed
        endX = (endX >= graphPoints.count) ? graphPoints.count - 1 : endX
        endX = (endX < 0) ? 0 : endX
        
        updateXLabels()
        updateYLabels()
        
        self.setNeedsDisplay()
    }
    
    private func initialize() {
        
        self.delegate = self
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.insetsLayoutMarginsFromSafeArea = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func drawGraph() {
        
        // 그래프 선분
        let graphPath = UIBezierPath()
        
        // 시작점(0, 0)
        var nextPoint = CGPoint(
            x: calculateCoordX(index: beginX - 1),
            y: calculateCoordY(index: beginX - 1)
        )
        graphPath.move(to: nextPoint)
        
        // graphPoints의 값들을 이용해 그래프에 값 추가
        for i in beginX...endX {
            nextPoint = CGPoint(
                x: intervalWidth / 2 + calculateCoordX(index: i),
                y: calculateCoordY(index: i)
                
            )
            graphPath.addLine(to: nextPoint)
        }
        
        nextPoint = CGPoint(
            x: intervalWidth / 2 + calculateCoordX(index: endX + 1),
            y: calculateCoordY(index: endX + 1)
        )
        graphPath.addLine(to: nextPoint)
        
        // 그래프 꺾은 선의 하단에 그레디언트 효과
        guard let graphAreaPath = graphPath.copy() as? UIBezierPath else {
            return
        }
        
        graphAreaPath.addLine(to: CGPoint(
            x: intervalWidth / 2 + calculateCoordX(index: endX + 1),
            y: self.frame.height - bottomBorder)
        )
        
        graphAreaPath.addLine(to: CGPoint(
            x: calculateCoordX(index: beginX - 1),
            y: self.frame.height - bottomBorder)
        )
        
        let graphColor = UIColor.primary
        graphColor.setFill()
        graphAreaPath.close()
        graphAreaPath.fill(with: .hardLight, alpha: 0.2)
        
        graphColor.setStroke()
        graphPath.lineWidth = 2.0
        graphPath.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        
        if isInstalled {
            setContents()
            isInstalled = false
        } else {
            if needXLabelUpdated {
                updateXLabels()
            }
            
            if needYLabelUpdated {
                updateYLabels()
            }
        }
        
        if graphPoints.count > 0 {
            drawGraph()
        }
        
        let referencelineColor = UIColor.lightGray
        referencelineColor.setStroke()
        
        referenceLinePath?.lineWidth = 0.5
        referenceLinePath?.stroke()
    }
    
    /// X 좌표 구하기
    private func calculateCoordX(index: Int) -> CGFloat {
        
        let columnsCount = self.graphPoints.count
        guard index >= 0 else {
            return margin
        }
        
        guard index < columnsCount else {
            return (CGFloat(columnsCount) + 0.5) * intervalWidth - margin
        }
        
        var x: CGFloat = (CGFloat(index) + 0.5) * intervalWidth
        x += self.margin
        
        return x
    }
    
    /// Y 좌표 구하기
    private func calculateCoordY(index: Int) -> CGFloat {
        
        let sortedGraphPoint:[String] = graphPoints.keys.sorted(by: <)
        
        guard
            0 <= index && index < graphPoints.count,
            let graphPoint = graphPoints[sortedGraphPoint[index]]
            else {
                return CGFloat(self.frame.height - bottomBorder)
        }
        
        let graphHeight = self.frame.height - topBorder - bottomBorder
        
        var y: CGFloat
        
        y = (CGFloat(graphPoint) / CGFloat(graphPoints.values.max() ?? 1)) * graphHeight
        y = graphHeight + topBorder - y // Flip the graph
        
        return y
    }
    
    private func updateXLabels() {
        
        print("(x, y) = (\(beginX), \(endX))")
        
        let sortedGraphLabels:[String] = graphPoints.keys.sorted(by: <)
        
        for xLabel in xLabels {
            xLabel.removeFromSuperview()
        }
        xLabels.removeAll()
        
        if sortedGraphLabels.count > 0 {
            for i in beginX...endX {
                let frame = CGRect(
                    x: calculateCoordX(index: i),
                    y: self.frame.height - bottomBorder,
                    width: intervalWidth * 0.75,
                    height: labelSize / 2
                )
                let xLabel = UILabel(frame: frame)
                xLabel.text = "\(sortedGraphLabels[i])"
                xLabel.adjustsFontSizeToFitWidth = true
                xLabel.textAlignment = .center
                
                xLabels.append(xLabel)
                self.addSubview(xLabel)
            }
        }
        
        let firstX = calculateCoordX(index: beginX - 1)
        let lastX = firstX + self.frame.width + intervalWidth + 2 * margin
        
        //Draw horizontal graph lines on the top of everything
        referenceLinePath = UIBezierPath()
        
        let graphHeight = self.frame.height - topBorder - bottomBorder
        for i in 1...5 {
            let yPos = (graphHeight + topBorder) - (CGFloat(5 - i) / 4.0) * graphHeight
            
            referenceLinePath?.move(to: CGPoint(x: firstX, y: yPos))
            referenceLinePath?.addLine(to: CGPoint(x: lastX, y: yPos))
        }
        
        needXLabelUpdated = false
    }
    
    private func updateYLabels() {
        
        print(#function)
        print("frame: ", self.frame)
        
        for label in yLabels {          // 기존 y Label 제거
            label.removeFromSuperview()
        }
        yLabels.removeAll()
        
        let graphHeight = self.frame.height - topBorder - bottomBorder
        
        var yValue = (graphPoints.values.max() ?? 1.0)
        let intervalHeight = yValue / 4
        
        for i in 1 ..< 5 {
            
            let yPos = (graphHeight + topBorder) - (CGFloat(5 - i) / 4.0) * graphHeight
            
            let frame = CGRect(
                x: 0,
                y: yPos - CGFloat(labelSize) / 2.0,
                width: labelSize,
                height: labelSize
            )
            
            let yLabel = UILabel(frame: frame)
            
            yLabel.text = "\(yValue.roundTo(places: 1))"
            yLabel.textAlignment = .left
            yLabel.font = yLabel.font.withSize(10)
            
            yLabels.append(yLabel)
            self.addSubview(yLabel)
            
            yValue -= intervalHeight
        }
        
        needYLabelUpdated = false
    }
}

extension GraphView : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard intervalWidth > 0 else {
            return
        }
        
        var nextBeginX = Int(scrollView.contentOffset.x / intervalWidth)
        nextBeginX = (nextBeginX >= graphPoints.count) ? 0 : nextBeginX
        nextBeginX = (nextBeginX < 0) ? 0 : nextBeginX
        
        if beginX != nextBeginX {
            
            beginX = nextBeginX
            
            endX = beginX + numOfPointsShowed
            endX = (endX >= graphPoints.count) ? graphPoints.count - 1 : endX
            endX = (endX < 0) ? 0 : endX
            
            needXLabelUpdated = true
        }
        
        self.setNeedsDisplay()
    }
}

