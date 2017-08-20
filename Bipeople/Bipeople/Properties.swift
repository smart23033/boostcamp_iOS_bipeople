//
//  Properties.swift
//  Bipeople
//
//  Created by YeongSik Lee on 2017. 8. 12..
//  Copyright © 2017년 BluePotato. All rights reserved.
//

import Foundation

/// GeoJSON 표준 규격 사용자 정의 프로퍼티 정보
class Properties: Codable {
    
    /**
     *  공통 정보
     */
    var index: Int?                 /// 경로 순번, 필수 X, Ex) 1
    var name: String?               /// 안내지점의 명칭, 필수 X, Ex) 서울시청
    var description: String?        /// 길 안내 정보, 필수 X, Ex) 좌회전 후 500m
    var facilityType: String?       /// 구간 시설물 타입, 필수 X,
    var facilityName: String?       /// 구간 시설물 타입의 명칭 Ex) 교량
    
    /**
     *  geometry - type : "Point"
     */
    var pointIndex: Int?            /// 안내점 노드 순번, 필수 X, Ex) 1
    var direction: String?          /// 방면 명칭, 필수 X, Ex) 직진
    var intersectionName: String?  /// 교차로 명칭, 필수 X, Ex) - 0: 왕십리역 오거리
    var nearPoiX: String?           /// 안내지점 근방 poi X좌표, 필수 X,
    var nearPoiY: String?           /// 안내지점 근방 poi Y좌표, 필수 X,
    var nearPoiName: String?        /// 안내지점 근방 poi, 필수 X,
    var turnType: Int?              /// 회전 정보, 필수 X,
    var pointType: String?          /// 안내지점의 구분, 필수 X,수 X, Ex) 교량
    var totalDistance: Int?         /// 경로 총 구간길이(단위: m), pointType = SP 일때 응답되는 정보, 필수 X, Ex) 3000
    var totalTime: Int?             /// 경로 총 소요시간(단위: 초), pointType = SP 일때 응답되는 정보, 필수 X, Ex) 600
    
    /**
     *  geometry - type : "LineString"
     */
    var lineIndex: Int?             /// 구간의 순번, 필수 X, Ex) 1
    var time: Int?                  /// 경로의 소요시간 (단위 : 초), 필수 X,
    var distance: Int?              /// 경로의 구간거리 (단위 : m), 필수 X,
    var roadType: Int?              /// 도로타입 코드, 필수 X,
    var categoryRoadType: Int?      /// 특화거리 코드, 필수 X
}
