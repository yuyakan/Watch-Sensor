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
        var csv = zipSensorData(allData: getSensorModel.getDataLog())
            .joined(separator: "\n")
        
        let title: String = "time, accelerationX, accelerationY, accelerationZ, rotationRateX, rotationRateY, rotationRateZ, gravityX, gravityY, gravityZ, pich, roll, yaw\n"
        
        csv = title + csv
        
        //mock
        //        csv = title + "1, 1, 1, 1, 1, 1, 1\n1, 1, 1, 1, 1, 1, 1"
        
        return csv
    }
    
    private func zipSensorData(allData: allData) -> [String] {
        let zip2Data = zip2Array(array1: allData.timeStamp, array2: allData.accelerationData.X)
        let zip3Data = zip2Array(array1: zip2Data, array2: allData.accelerationData.Y)
        let zip4Data = zip2Array(array1: zip3Data, array2: allData.accelerationData.Z)
        
        let zip5Data = zip2Array(array1: zip4Data, array2: allData.rotationData.X)
        let zip6Data = zip2Array(array1: zip5Data, array2: allData.rotationData.Y)
        let zip7Data = zip2Array(array1: zip6Data, array2: allData.rotationData.Z)
        
        let zip8Data = zip2Array(array1: zip7Data, array2: allData.gravityData.X)
        let zip9Data = zip2Array(array1: zip8Data, array2: allData.gravityData.Y)
        let zip10Data = zip2Array(array1: zip9Data, array2: allData.gravityData.Z)
        
        let zip11Data = zip2Array(array1: zip10Data, array2: allData.atitudeData.X)
        let zip12Data = zip2Array(array1: zip11Data, array2: allData.atitudeData.Y)
        let zip13Data = zip2Array(array1: zip12Data, array2: allData.atitudeData.Z)
        
        return zip13Data
    }
    
    private func zip2Array(array1: Array<Any>, array2: Array<Any>) -> [String] {
        zip(array1, array2).map { nums in "\(nums.0), \(nums.1)" }
    }
    
    
    func createGpsCsv() -> String {
        var csv = zip(zip(getSensorModel.getDataLog().gpsData.gpsTimeStamp, getSensorModel.getDataLog().gpsData.latitude).map{ log in "\(log.0), \(log.1)" }
                      , getSensorModel.getDataLog().gpsData.longitude).map{ log in "\(log.0), \(log.1)" }
            .joined(separator: "\n")
        
        let title: String = "time, latitude, longitude\n"
        
        csv = title + csv
        
        //mock
//        csv = title + "1, 1, 1\n1, 1, 1"
        
        return csv
    }
    
}
