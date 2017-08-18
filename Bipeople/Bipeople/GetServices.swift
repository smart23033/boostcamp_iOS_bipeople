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


class GetServices {
    
    static func fetchList <T: Codable> (url:String, _ type: T.Type, success:@escaping (T) -> Void, fail:@escaping (_ error:NSError)->Void)->Void  {
        guard let url = URL(string: url) else { return }
        Alamofire
            .request(url)
            .responseJSON { response in
                
                guard let data = response.data else { return }
                
                do {
                    let decoded = try JSONDecoder().decode(
                        T.self,
                        from: data
                    )
                    
                    success(decoded)
                } catch {
                    print("Not working with: ", error)
                }
        }
    }
    
}

