//
//  AllData.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/03.
//

import Foundation


struct allData {
    var timeStamp: [Double]
    var accelerationData: sensorData
    var rotationData: sensorData
    var gpsData: gpsData
    
    var gravityData: sensorData
    var atitudeData: sensorData
}
