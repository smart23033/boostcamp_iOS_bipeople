//
//  PlaceInfoCell.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 17..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit

class PlaceInfoCell: UICollectionViewCell {
    @IBOutlet var classifyTextField: UITextField!
    @IBOutlet var locationTextField: UITextField!
    @IBOutlet var latitudeTextField: UITextField!
    @IBOutlet var longitudeTextField: UITextField!
    @IBOutlet var imageView: UIImageView! {
        didSet {
            imageView.image = UIImage(named:"no-image-half-landscape")
        }
    }
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
        }
    }
    
    var imageURL: URL? {
        didSet {
            image = UIImage(named: "no-image-half-landscape")
            fetchImage()
        }
    }
    
    func fetchImage() {
        
        guard let url = imageURL else { return }
        let urlContents = try? Data(contentsOf: url)
        if let imageData = urlContents {
            image = UIImage(data: imageData)
        }
    }
}
