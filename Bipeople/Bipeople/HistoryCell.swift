//
//  HistoryCell.swift
//  Bipeople
//
//  Created by 김성준 on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import MarqueeLabel

class HistoryCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: MarqueeLabel! {
        didSet {
            titleLabel.type = .continuous
            titleLabel.speed = .duration(10)
            titleLabel.fadeLength = 20.0
            titleLabel.leadingBuffer = 30.0
        }
    }
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
}
