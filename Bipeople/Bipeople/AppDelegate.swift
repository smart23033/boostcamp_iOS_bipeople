//
//  AppDelegate.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 7..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var records = [Record]()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        /**
          * Add Google Map API Key
          */
        GMSServices.provideAPIKey("AIzaSyDHNdS74dfE2fMYP4CLMJ9wfipk4XZB7dw")
        GMSPlacesClient.provideAPIKey("AIzaSyDHNdS74dfE2fMYP4CLMJ9wfipk4XZB7dw")
        
        // Override point for customization after application launch.
        
        let tabBarController = window?.rootViewController as! UITabBarController
        let navControllers = tabBarController.childViewControllers as! [UINavigationController]
     
        // 리터럴값 보기 좀 그렇다.
        tabBarController.selectedIndex = 2
        
        changeTheme(navigationControllers: navControllers)
        
        RealmHelper.fetchData(dataList: &records)
        
        
        /* 더미데이터 삽입 */
        RealmHelper.removeAllData()
        records.removeAll()
    
        for i in 0..<20 {
            let record = Record(departure: "departure \(i)",
                arrival: "arrival \(i)",
                distance: Double(arc4random_uniform(1000)) / Double(10),
                ridingTime: Double(arc4random_uniform(1000)) / Double(10),
                restTime: Double(arc4random_uniform(1000)) / Double(10),
                averageSpeed: Double(arc4random_uniform(1000)) / Double(10),
                highestSpeed: Double(arc4random_uniform(1000)) / Double(10),
                calories: Double(arc4random_uniform(1000)) / Double(10))
            
            RealmHelper.addData(data: record)
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

extension AppDelegate {
    
    func changeTheme(navigationControllers: [UINavigationController]) {
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.delegate?.window??.tintColor = UIColor.primaryColor
        
        navigationControllers.forEach { (nvc) in
            nvc.topViewController?.navigationController?.navigationBar.isTranslucent = false
            nvc.topViewController?.navigationController?.navigationBar.barTintColor = UIColor.primaryColor
            nvc.topViewController?.navigationController?.navigationBar.tintColor = .white
            nvc.topViewController?.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        }
        
        
    }
}
