//
//  CreateCsv.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/03.
//

import Foundation

class CreateCsv {
    let getSensorModel = GetSenorModel.shared
    
    func createMotionCsv() -> String {
        var csv = zip(zip(zip(zip(zip(zip(getSensorModel.getDataLog().timeStamp, getSensorModel.getDataLog().accelerationData.X).map{ log in "\(log.0), \(log.1)"}
                                      , getSensorModel.getDataLog().accelerationData.Y).map{ log in "\(log.0), \(log.1)" }
                                  , getSensorModel.getDataLog().accelerationData.Z).map{ log in "\(log.0), \(log.1)" }
                              , getSensorModel.getDataLog().rotationData.X).map{ log in "\(log.0), \(log.1)" }
                          , getSensorModel.getDataLog().rotationData.Y).map{ log in "\(log.0), \(log.1)" }
                      , getSensorModel.getDataLog().rotationData.Z).map{ log in "\(log.0), \(log.1)" }
            .joined(separator: "\n")
        
        let title: String = "time, accelerationX, accelerationY, accelerationZ, rotationRateX, rotationRateY, rotationRateZ\n"
        
        csv = title + csv
        
        //mock
        csv = title + "1, 1, 1, 1, 1, 1, 1\n1, 1, 1, 1, 1, 1, 1"
        
        return csv
    }
    
    func createGpsCsv() -> String {
        var csv = zip(zip(getSensorModel.getDataLog().gpsData.gpsTimeStamp, getSensorModel.getDataLog().gpsData.latitude).map{ log in "\(log.0), \(log.1)" }
                      , getSensorModel.getDataLog().gpsData.longitude).map{ log in "\(log.0), \(log.1)" }
            .joined(separator: "\n")
        
        let title: String = "time, latitude, longitude\n"
        
        csv = title + csv
        
        //mock
        csv = title + "1, 1, 1\n1, 1, 1"
        
        return csv
    }
    
    func crateGravityAndAttitudeCsv() -> String {
        var csv = zip(zip(zip(zip(zip(zip(getSensorModel.getDataLog().timeStamp, getSensorModel.getDataLog().gravityData.X).map{ log in "\(log.0), \(log.1)"}
                                      , getSensorModel.getDataLog().gravityData.Y).map{ log in "\(log.0), \(log.1)" }
                                  , getSensorModel.getDataLog().gravityData.Z).map{ log in "\(log.0), \(log.1)" }
                              , getSensorModel.getDataLog().atitudeData.X).map{ log in "\(log.0), \(log.1)" }
                          , getSensorModel.getDataLog().atitudeData.Y).map{ log in "\(log.0), \(log.1)" }
                      , getSensorModel.getDataLog().atitudeData.Z).map{ log in "\(log.0), \(log.1)" }
            .joined(separator: "\n")
        
        let title: String = "time, gravityX, gravityY, gravityZ, pich, roll, yaw\n"
        
        csv = title + csv
        
        //mock
        csv = title + "1, 1, 1, 1, 1, 1, 1\n1, 1, 1, 1, 1, 1, 1"
        
        return csv
    }
    
}
