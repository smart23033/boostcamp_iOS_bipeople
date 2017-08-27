//
//  PlaceDetailViewController.swift
//  Bipeople
//
//  Created by 조준영 on 2017. 8. 15..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import GoogleMaps

class PlaceDetailViewController: UIViewController {
    
    //MARK: Outlets
    
    @IBOutlet var placeAddressLabel: UILabel!
    @IBOutlet var placeMapView: GMSMapView!
    @IBOutlet var placesTableView: UITableView!
    
    //MARK: Properties
    
    var selectedPlace : PublicPlace?
    var nearPlaces: [PublicPlace] = []
    var sameTypePlaces: [PublicPlace] = []
    var isNavigationOn: Bool = false
    
    lazy var findRouteButton: UIBarButtonItem = .init(title: "이동", style: .done, target: self, action: nil)
    lazy var backButton: UIBarButtonItem = .init(title: "뒤로", style: .done, target: self, action: #selector(popAllViewControllers))
    
    func findRouteAndDrawForPlace() {
        
    }
    
    //MARK: Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.leftBarButtonItem = backButton
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
        marker.icon = UIImage(named: place.placeType.imageName)
        marker.map = placeMapView
        
        
    }
    
    //MARK: Functions
    
    @objc func popAllViewControllers() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}

//MARK: UITableViewDelegate

extension PlaceDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        nearPlaces.forEach { (place) in
            if place.placeType.description == selectedPlace?.placeType.description {
                count += 1
            }
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PlacesTableCell")
        
        sameTypePlaces = nearPlaces.filter { $0.placeType.description == selectedPlace?.placeType.description }
        
        let place = sameTypePlaces[indexPath.row]
        
        cell.textLabel?.text = place.title
        cell.accessoryView = UIImageView(image: UIImage(named: place.placeType.imageName))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let placeVC = self.storyboard?.instantiateViewController(withIdentifier: "PlaceDetailViewController") as? PlaceDetailViewController else {
            return
        }
        
        sameTypePlaces = nearPlaces.filter { $0.placeType.description == selectedPlace?.placeType.description }
        
        placeVC.selectedPlace = sameTypePlaces[indexPath.row]
        placeVC.nearPlaces = self.nearPlaces
      
        self.navigationController?.pushViewController(placeVC, animated: true);
        
    }
    
}
