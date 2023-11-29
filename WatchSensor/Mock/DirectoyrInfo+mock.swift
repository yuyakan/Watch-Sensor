//
//  DirectoyrInfo+mock.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/12.
//

import Foundation

struct DirectoryInfoMock {
    var directoryName: String = ""
    
    static let mock1 = DirectoryInfoMock(directoryName: NSHomeDirectory() + "/Documents/" + FileInfo.mock1.directoryInfo)
    static let mock2 = DirectoryInfoMock(directoryName: NSHomeDirectory() + "/Documents/" + FileInfo.mock2.directoryInfo)
}
