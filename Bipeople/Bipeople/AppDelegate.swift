//
//  AppDelegate.swift
//  Bipeople
//
//  Created by BluePotato on 2017. 8. 7..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let GOOGLE_API_KEY = "AIzaSyDHNdS74dfE2fMYP4CLMJ9wfipk4XZB7dw"
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        print(Realm.Configuration.defaultConfiguration.fileURL ?? "No path for realm") // FOR DEBUG
        
        // RealmHelper.deleteAll() // FOR DEBUG
        updatePublicPlaceInfoFromNetwork()
        /**
          * Add Google Map API Key
          */
        GMSServices.provideAPIKey(AppDelegate.GOOGLE_API_KEY)
        GMSPlacesClient.provideAPIKey(AppDelegate.GOOGLE_API_KEY)
        
        // Override point for customization after application launch.
        
        let tabBarController = window!.rootViewController as! UITabBarController
        let navControllers = tabBarController.childViewControllers as! [UINavigationController]
        
        changeTheme(navigationControllers: navControllers)
        
        /* FOR DEBUG: 더미데이터 삽입 시작 */
//        RealmHelper.deleteTable(of: Record.self)
//        for i in 0 ..< 5 {
//            let record = Record(departure: "departure \(i)",
//                arrival: "arrival \(i)",
//                distance: Double(arc4random_uniform(1000)) / Double(10),
//                ridingTime: Double(arc4random_uniform(1000)) / Double(10),
//                restTime: Double(arc4random_uniform(1000)) / Double(10),
//                averageSpeed: Double(arc4random_uniform(1000)) / Double(10),
//                maximumSpeed: Double(arc4random_uniform(1000)) / Double(10),
//                calories: Double(arc4random_uniform(1000)) / Double(10))
//
//            RealmHelper.add(data: record)
//        }
//        RealmHelper.deleteTable(of: Trace.self)
        /* FOR DEBUG: 더미데이터 삽입 끝 */
        
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
    
    func updatePublicPlaceInfoFromNetwork() {
        
        RealmHelper.deleteTable(of: PublicPlace.self)
        
        PublicPlace.fetchList(apiURL: .toiletURL, PublicToilet.self, success: { response in
            
            let toilet = response.searchPublicToiletPOIService.row.map { toilet -> PublicPlace in
                
                let place = PublicPlace()
                
                place.lat = toilet.y_Wgs84
                place.lng = toilet.x_Wgs84
                place.placeType = .toilet
                place.location = toilet.fName
                
                return place
            }
            
            let realm = try! Realm()
            try! realm.write {
                realm.add(toilet)
            }
        }) { error in
            print("Error in", #function)    // FOR DEBUG
        }
        
        PublicPlace.fetchList(apiURL : .wifiURL, PublicWiFi.self, success: { response in
            
            let wifi = response.publicWiFiPlaceInfo.row.map { wifi -> PublicPlace in
            
                let place = PublicPlace()
                
                place.lat = wifi.INSTL_Y
                place.lng = wifi.INSTL_X
                place.placeType = .wifi
                place.location = wifi.PLACE_NAME
                
                return place
            }

            let realm = try! Realm()
            try! realm.write {
                realm.add(wifi)
            }
        }) { error in
            print("Error in", #function)    // FOR DEBUG
        }
        
        PublicPlace.fetchList(apiURL : .storeURL, PublicStore.self, success: { response in
            
            let store = response.geoInfoBikeConvenientFacilitiesWGS.row.map { store -> PublicPlace in
                
                let place = PublicPlace()
                
                place.lat = Double(store.LAT) ?? 0.0
                place.lng = Double(store.LNG) ?? 0.0
                place.placeType = .store
                place.location = store.ADDRESS
                place.imageURL = store.FILENAME
                
                return place
            }
            
            let realm = try! Realm()
            try! realm.write {
                realm.add(store)
            }
        }) { error in
            print("Error in", #function)    // FOR DEBUG
        }
    }
}
