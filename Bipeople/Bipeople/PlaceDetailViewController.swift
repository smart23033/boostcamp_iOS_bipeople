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
    
    var selectedPlace : PublicPlace?
    var nearPlaces: [PublicPlace] = []
    var isNavigationOn: Bool = false
    
    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var placeMapView: GMSMapView!
    @IBOutlet weak var placesTableView: UITableView!
    
    lazy var findRouteButton: UIBarButtonItem = .init(title: "바로가기", style: .done, target: self, action: nil)
    
    func findRouteAndDrawForPlace() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.rightBarButtonItem = isNavigationOn ? nil : findRouteButton
        
        self.navigationItem.title = selectedPlace?.title
        self.placeAddressLabel.text = selectedPlace?.address
        
        guard let place = selectedPlace else {
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
        
        return nearPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PlacesTableCell")
        let place = nearPlaces[indexPath.row]
        
        cell.textLabel?.text = place.title
        cell.accessoryView = UIImageView(image: UIImage(named: place.placeType.description))
        
        return cell
    }
}
