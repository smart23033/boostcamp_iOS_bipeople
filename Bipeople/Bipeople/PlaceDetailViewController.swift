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
    
    public var selectedPlace : PublicPlace?
    public var nearPlaces: [PublicPlace] = []
    public var sameTypePlaces: [PublicPlace] = []
    public var isNavigationOn: Bool = false

    
    //MARK: IBOutlet
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    @IBOutlet weak var moveButton: UIBarButtonItem!
    
    
    //MARK: IBAction
    
    @IBAction func didTapBackButton(_ sender: Any) {
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func didTapMoveButton(_ sender: Any) {
        
        self.performSegue(withIdentifier: "MoveToPlace", sender: self)
    }
    
    
    //MARK: Life Cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
}

//MARK: UITableViewDelegate

extension PlaceDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let selectedPlace = selectedPlace else {
            return 0
        }
        
        var count = 0
        nearPlaces.forEach { (place) in
            if place.placeType.description == selectedPlace.placeType.description {
                count += 1
            }
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "PlacesTableCell")
        
        sameTypePlaces = nearPlaces.filter { $0.placeType.description == selectedPlace?.placeType.description }
        
        let place = sameTypePlaces[indexPath.row]
        
        cell.textLabel?.text = place.address
        cell.accessoryView = UIImageView(image: UIImage(named: place.placeType.imageName))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard
            let instanceVC = self.storyboard?.instantiateViewController(withIdentifier: "PlaceDetailViewController"),
            let placeDetailVC = instanceVC as? PlaceDetailViewController
        else {
            return
        }
        
        sameTypePlaces = nearPlaces.filter { $0.placeType.description == selectedPlace?.placeType.description }
        
        placeDetailVC.selectedPlace = sameTypePlaces[indexPath.row]
        placeDetailVC.nearPlaces = self.nearPlaces
      
        self.navigationController?.pushViewController(placeDetailVC, animated: true);
    }
}
