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
    var places = [PublicPlace]()
    
    @IBOutlet weak var placeTypeLabel: UILabel!
    @IBOutlet weak var placeMapView: GMSMapView!
    @IBOutlet weak var placesTableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.title = place?.location
        self.placeTypeLabel.text = place?.placeType.rawValue
        
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
        marker.icon = (place.placeType == .none) ? nil : UIImage(named: place.placeType.rawValue)
        marker.map = placeMapView
    }
    
    @objc func unwindToMap() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension PlaceDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let place = places[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PlacesTableCell")
        
        cell.textLabel?.text = place.location
        cell.accessoryView = (place.placeType == .none)
            ? nil : UIImageView(image: UIImage(named: place.placeType.rawValue))
        
        return cell
    }
}
