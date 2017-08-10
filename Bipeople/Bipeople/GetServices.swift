//
//  FetchData.swift
//  Bipeople
//
//  Created by BLU on 2017. 8. 8..
//  Copyright © 2017년 futr_blu. All rights reserved.
//

import Foundation
import Alamofire
import RealmSwift
import CodableAlamofire


class GetServices {
    static func fetchList <T: Codable> (_ type: T.Type, success:@escaping (Any) -> Void, fail:@escaping (_ error:NSError)->Void)->Void  {
        Alamofire
            .request(URL(string: "http://openAPI.seoul.go.kr:8088/4944627561736d613130334c75587853/json/SearchPublicToiletPOIService/1/200/")!)
            
            .responseJSON { response in
                print(response.data!)
                print(response)
                
                //                let response: DataResponse<T> = response.flatMap {
                //                    json in
                //                    print(json)
                //                }
                //                switch response.result.value {
                //                case .some(let items):
                //                    print(response)
                //                //print(items)
                //                case .none:
                //                    print("없다")
                //                }
                //                do {
                //                    let decoded = try JSONDecoder().decode(
                //                        PublicResponse.self,
                //                        from: response.data!
                //                    )
                //
                //                    print("decoded:", decoded)
                //                } catch {
                //                    print("\(error)")
                //                }
                if let decoded = try? JSONDecoder().decode(
                    PublicResponse.self,
                    from: response.data!
                    ) {
                    print("decoded:", decoded)
                    success(decoded)
                } else {
                    print("Not working")
                }
                
                
        }
    }
    //    static func fetchTest() {
    //        let url = URL(string: "http://openAPI.seoul.go.kr:8088/4944627561736d613130334c75587853/json/SearchPublicToiletPOIService/1/200/")!
    //        let decoder = JSONDecoder()
    //        decoder.dateDecodingStrategy = .secondsSince1970 // It is necessary for correct decoding. Timestamp -> Date.
    //
    //        Alamofire.request(url).responseDecodableObject(keyPath: nil, decoder: decoder) { (response: DataResponse<[PublicResponse]>) in
    //            let repo = response.result.value
    //            print(repo)
    //        }
    //    }
    
    
}

