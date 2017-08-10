//
//  PlaceListVC.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import UIKit
import Alamofire

class PlaceListVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //        Alamofire.request("http://openAPI.seoul.go.kr:8088/4944627561736d613130334c75587853/json/SearchPublicToiletPOIService/1/200/",
        //                          encoding: JSONEncoding.default)
        //            .validate()
        //            .responseJSONCodable(configurationHandler: { decoder in
        //
        //                print(decoder)
        //            }) { (dataResp: DataResponse<PublicResponse>) in
        //                print(dataResp)
        ////                guard let person = dataResp.value else { return }
        ////                guard let jsonString = self.jsonString(from: person) else { return }
        ////                self.jsonTextView.text = jsonString
        //        }
        
        //GetServices.fetchTest()
        GetServices.fetchList(PublicResponse.self, success: {_ in
            print("성공")
        }){ (error) in
            print("에러")
        }
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

