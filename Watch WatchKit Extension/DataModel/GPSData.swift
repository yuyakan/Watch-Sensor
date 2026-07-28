//
//  GPSData.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/03.
//

import Foundation


struct gpsData {
    /// GPS 取得時の絶対時刻（"HH:mm:ss"）。従来からの互換フィールド。
    var gpsTimeStamp: [String]
    /// motion と同じ「計測開始からの相対経過秒」。motion データと時間軸で突き合わせるために使う。
    var elapsedTime: [Double]
    var latitude: [Double]
    var longitude: [Double]
}
