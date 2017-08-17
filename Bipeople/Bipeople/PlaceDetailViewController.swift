//
//  PlaceDetailViewController.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 15..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit

class PlaceDetailViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.isPagingEnabled = true
            collectionView.register(UINib(nibName: "PlaceListCell", bundle: nil), forCellWithReuseIdentifier: "PlaceListCell")
            collectionView.register(UINib(nibName: "PlaceInfoCell", bundle: nil), forCellWithReuseIdentifier: "PlaceInfoCell")
        }
    }
    
    let tapGesture : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(unwindToMap))
    var place : Place?
    var places = [Place]()
    
    override func viewWillAppear(_ animated: Bool) {
        //self.extendedLayoutIncludesOpaqueBars = true
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func unwindToMap() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension PlaceDetailViewController : UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceInfoCell", for: indexPath) as! PlaceInfoCell
            cell.classifyTextField.text = place?.placeType.rawValue
            cell.locationTextField.text = place?.location
            cell.latitudeTextField.text = String(describing: place?.lat)
            cell.longitudeTextField.text = String(describing: place?.lng)
            cell.imageURL = URL(string: (place?.imageURL)!)
            
            return cell
        } else {
            let placeListCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceListCell", for: indexPath) as! PlaceListCell
            placeListCell.places = self.places
            placeListCell.place = self.place
            placeListCell.setup()
            placeListCell.reloadAndResizeTable()
            placeListCell.mapViewLayer.addTarget(self,
                                                 action: #selector(unwindToMap),
                                                 for: .touchUpInside)
            //            tapGesture.numberOfTapsRequired = 1
            //            placeListCell.mapViewLayer.isUserInteractionEnabled = true
            //            placeListCell.mapViewLayer.addGestureRecognizer(tapGesture)
            
            return placeListCell
        }
    }
}


extension PlaceDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize{
        if indexPath.row == 0 {
            return CGSize(width: self.view.frame.width, height: self.view.frame.height - 64)
        } else {
            let tableViewHeight = places.count * 44
            let cellHeight : CGFloat = CGFloat(tableViewHeight) + 404.0
            return CGSize(width: self.view.frame.width, height: cellHeight)
        }
        
    }
    
}

