//
//  PlaceDetailViewController.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 15..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import GoogleMaps

class PlaceDetailViewController: UIViewController {
    
    var place : PublicPlace?
    var places: [PublicPlace]?
    
    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var placeMapView: GMSMapView!
    @IBOutlet weak var placesTableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = place?.title
        self.placeAddressLabel.text = place?.address
        
        guard let place = place else {
            return
        }
        
        let position = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng)
        
        placeMapView.camera = GMSCameraPosition.camera(
            withLatitude: position.latitude,
            longitude: position.longitude,
            zoom: 17
        )
        
        let marker = GMSMarker(position: position)
        marker.icon = UIImage(named: place.placeType.description)
        marker.map = placeMapView
    }
    
    @objc func unwindToMap() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension PlaceDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return places?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PlacesTableCell")
        
        guard let place = places?[indexPath.row] else {
            return cell
        }
        
        cell.textLabel?.text = place.title
        cell.accessoryView = UIImageView(image: UIImage(named: place.placeType.description))
        
        return cell
    }
}
