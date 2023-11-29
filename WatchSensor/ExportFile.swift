//
//  ExportFile.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/05.
//

import Foundation
import UIKit

class ExportFile {
    let fileManager = FileManager.default
    
    func exportFiles(fileInfo: FileInfo) -> Bool {
        let directory = NSHomeDirectory() + "/Documents/" + fileInfo.directoryInfo
        let isDirectoryCreated = createDirectory(directory: directory)
        let isSensorFileExported = exportFile(directory: directory, Info: fileInfo.sensorInfo)
        let isGpsFileExported = exportFile(directory: directory, Info: fileInfo.gpsInfo)
        let isGravityAndAttitudeFileExported = exportFile(directory: directory, Info: fileInfo.gravityAndAttitudeInfo)
        
        if isDirectoryCreated && isSensorFileExported && isGpsFileExported && isGravityAndAttitudeFileExported {
            return true
        }
        return false
    }
    
    func createDirectory(directory: String) -> Bool {
        do {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        } catch {
            return false
        }
        return true
    }
    
    func exportFile(directory: String, Info: [String]) -> Bool {
        do {
            let path = directory + "/" + Info[0]
            try Info[1].write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            return false
        }
        return true
    }
    
}
