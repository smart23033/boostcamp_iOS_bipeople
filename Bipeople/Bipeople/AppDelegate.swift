//
//  AppDelegate.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 7..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var records = [Record]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        savePlaces()
        print(Realm.Configuration.defaultConfiguration.fileURL ?? "No path for realm") // FOR DEBUG
        
        /**
          * Add Google Map API Key
          */
        GMSServices.provideAPIKey("AIzaSyDHNdS74dfE2fMYP4CLMJ9wfipk4XZB7dw")
        GMSPlacesClient.provideAPIKey("AIzaSyDHNdS74dfE2fMYP4CLMJ9wfipk4XZB7dw")
        
        // Override point for customization after application launch.
        
        let tabBarController = window?.rootViewController as! UITabBarController
        let navControllers = tabBarController.childViewControllers as! [UINavigationController]
        
        changeTheme(navigationControllers: navControllers)
        
        records = Array(RealmHelper.fetchFromType(of: Record()))
        
        /* 더미데이터 삽입 */
        // RealmHelper.removeAll()
        // records.removeAll()
    
        for i in 0 ..< 5 {
            let record = Record(departure: "departure \(i)",
                arrival: "arrival \(i)",
                distance: Double(arc4random_uniform(1000)) / Double(10),
                ridingTime: Double(arc4random_uniform(1000)) / Double(10),
                restTime: Double(arc4random_uniform(1000)) / Double(10),
                averageSpeed: Double(arc4random_uniform(1000)) / Double(10),
                maximumSpeed: Double(arc4random_uniform(1000)) / Double(10),
                calories: Double(arc4random_uniform(1000)) / Double(10))
            
            RealmHelper.add(data: record)
            records.append(record)
        }
        /* 더미데이터 삽입 */
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

//MARK: ChangeTheme

extension AppDelegate {
    
    func changeTheme(navigationControllers: [UINavigationController]) {
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.delegate?.window??.tintColor = UIColor.primary
        
        navigationControllers.forEach { (nvc) in
            nvc.topViewController?.navigationController?.navigationBar.isTranslucent = false
            nvc.topViewController?.navigationController?.navigationBar.barTintColor = UIColor.primary
            nvc.topViewController?.navigationController?.navigationBar.tintColor = .white
            nvc.topViewController?.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        }
    }
}

//MARK: GetPlaceInfo

extension AppDelegate {
    
    func savePlaces() {
        GetServices.fetchList(url : "http://openAPI.seoul.go.kr:8088/4944627561736d613130334c75587853/json/SearchPublicToiletPOIService/1/1000/" ,
            PublicToilet.self,
            success: { response in
            let toilets = response.searchPublicToiletPOIService.row
                .map { toilet -> Place in
                    let place = Place()
                    //place.id = Place.incrementID()
                    place.lat = toilet.y_Wgs84
                    place.lng = toilet.x_Wgs84
                    place.placeType = .toilet
                    place.location = toilet.fName
                    
                    return place
            }
            let realm = try! Realm()
            try! realm.write {
                realm.add(toilets)
            }
        }){ (error) in
            print("에러")
        }
        GetServices.fetchList(url : "http://openapi.seoul.go.kr:8088/6464794f66736d613131377946497a4d/json/PublicWiFiPlaceInfo/1/1000",
            PublicWiFi.self,
            success: { response in
            let wifis = response.publicWiFiPlaceInfo.row
                .map { wifi -> Place in
                    let place = Place()
                    //                    place.id = Place.incrementID()
                    place.lat = wifi.INSTL_Y
                    place.lng = wifi.INSTL_X
                    place.placeType = .wifi
                    place.location = wifi.PLACE_NAME
                    return place
            }

            let realm = try! Realm()
            try! realm.write {
                realm.add(wifis)
            }
        }){ (error) in
            print("에러")
        }
        
        GetServices.fetchList(
            url : "http://openapi.seoul.go.kr:8088/4467715062736d61313031666a6d5867/json/GeoInfoBikeConvenientFacilitiesWGS/1/1000/" ,
            PublicFacility.self,
            success: { response in
                let facilities = response.geoInfoBikeConvenientFacilitiesWGS.row
                    .map { facility -> Place in
                        let place = Place()
                        //place.id = Place.incrementID()
                        place.lat = Double(facility.LAT)!
                        place.lng = Double(facility.LNG)!
                        place.placeType = .store
                        place.location = facility.ADDRESS
                        place.imageURL = facility.FILENAME
                        
                        print("!!!!!!!", place.placeType)
                        
                        return place
                }
                let realm = try! Realm()
                try! realm.write {
                    realm.add(facilities)
                }
                
        }){ (error) in
            print("에러")
        }
    }
}
