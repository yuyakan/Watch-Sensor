//
//  FileInfo+mock.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/12.
//

import Foundation

extension FileInfo {
    static let mock1 = FileInfo(sensorInfo: ["123", "t, x, y, z, x, y, z\n1, 2, 3, 4, 5, 6, 7"], 
                                gpsInfo: ["123", "t, x, y\n1, 2, 3"],
                                directoryInfo: "123",
                                gravityAndAttitudeInfo: ["123", "t, x, y, z, x, y, z\n1, 2, 3, 4, 5, 6, 7"])
    
    static let mock2 = FileInfo(sensorInfo: ["123", "t, x, y, z, x, y, z\n1, 2, 3, 4, 5, 6, 7"],
                                gpsInfo: ["123", "t, x, y\n1, 2, 3"],
                                directoryInfo: "123",
                                gravityAndAttitudeInfo: ["123", "t, x, y, z, x, y, z\n1, 2, 3, 4, 5, 6, 7"])
}
