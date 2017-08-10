//
//  PlaceListVC.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit

class PlaceListVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        GetServices.fetchTest()
//        GetServices.fetchList(PublicResponse.self, success: {_ in
//            print("성공")
//        }){ (error) in
//            print("에러")
//        }
//        GetServices.fetchList(PublicResponse.self, success: {
//            print("성공")
//        }){ (error) in
//            print("에러")
//        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

