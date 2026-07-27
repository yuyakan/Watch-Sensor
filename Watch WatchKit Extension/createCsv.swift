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
        // getDataLog() は毎回スナップショットをコピーするため、1回だけ取得して使い回す。
        // （複数回呼ぶと計測中に長さがズレる可能性がある）
        let gps = getSensorModel.getDataLog().gpsData

        // 先頭に「計測開始からの相対経過秒(elapsedTime)」を出力し、motion CSV の time 列と
        // 同じ時間軸で突き合わせできるようにする。従来の絶対時刻(time)も残す。
        var rows: [String] = []
        for i in 0..<gps.latitude.count {
            let elapsed = i < gps.elapsedTime.count ? gps.elapsedTime[i] : 0.0
            let time = i < gps.gpsTimeStamp.count ? gps.gpsTimeStamp[i] : ""
            rows.append("\(elapsed), \(time), \(gps.latitude[i]), \(gps.longitude[i])")
        }

        let title: String = "elapsedTime, time, latitude, longitude\n"
        return title + rows.joined(separator: "\n")
    }
    
}
