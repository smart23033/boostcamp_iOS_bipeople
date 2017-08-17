//
//  ScrollableCell.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 15..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import GoogleMaps

class PlaceListCell: UICollectionViewCell {
    @IBOutlet var scrollView: UIScrollView! {
        didSet {
            
        }
    }
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.register(UITableViewCell.self,
                               forCellReuseIdentifier: "UITableViewCell")
            tableView.isScrollEnabled = false
        }
    }
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var mapView: GMSMapView! {
        didSet {
            mapView.layer.cornerRadius = 5
        }
    }
    
    @IBOutlet var mapViewLayer: UIButton!
    
    var places = [Place]()
    var place : Place?
    
}
extension PlaceListCell : UIScrollViewDelegate {
    
    func setup() {
        
        self.scrollView.delegate = self
        guard let place = place else {
            return
        }
        
        let position = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng)
        let camera = GMSCameraPosition.camera(
            withLatitude: position.latitude,
            longitude: position.longitude,
            zoom: 17
        )
        mapView.camera = camera
        let marker = GMSMarker(position: position)
        marker.title = place.placeType.rawValue
        marker.map = mapView
        
        print(place.placeType)
        if case .none = place.placeType {
            marker.icon = nil
        } else {
            marker.icon = UIImage(named: place.placeType.rawValue)
        }
    }
    
    func reloadAndResizeTable() {
        
        self.tableView.reloadData()
        DispatchQueue.main.async {
            self.tableViewHeightConstraint.constant = self.tableView.contentSize.height + 44
            self.scrollView.contentSize = CGSize(width: self.frame.width,
                                                 height: 404 + self.tableView.contentSize.height)
            print(self.tableView.contentSize.height)
            print(self.scrollView.contentSize)
            UIView.animate(withDuration: 0.4) {
                self.layoutIfNeeded()
            }
        }
        
    }
}
extension PlaceListCell : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return places.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let place = places[indexPath.row]
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "UITableViewCell")
        
        cell.textLabel?.text = place.location
        cell.detailTextLabel?.text = place.placeType.rawValue
        
        print(place.placeType)
        if case .none = place.placeType {
            cell.accessoryView = nil
        } else {
            cell.accessoryView = UIImageView(image: UIImage(named: place.placeType.rawValue))
        }
        
        return cell
    }
}

