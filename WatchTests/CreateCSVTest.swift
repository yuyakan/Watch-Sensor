//
//  CreateCSVTest.swift
//  WatchTests
//
//  Created by 上別縄祐也 on 2022/07/15.
//

import XCTest
@testable import Watch_WatchKit_Extension

extension GetSenorModel {
    func createMockDataLog() {
        setDataLogForTesting(
            allData(timeStamp: [0], accelerationData: sensorData(name: "acceleration", X: [1], Y: [2], Z: [3]),
                    rotationData:sensorData(name: "rotation", X: [1], Y: [2], Z: [3]),
                    gpsData: gpsData(gpsTimeStamp: ["0"], elapsedTime: [0], latitude: [1], longitude: [2]),
                    gravityData: sensorData(name: "gravity", X: [1], Y: [2], Z: [3]),
                    atitudeData: sensorData(name: "attitude", X: [1], Y: [2], Z: [3]))
        )
    }
}

class CreateCSVTest: XCTestCase {
    let getSensorModel = GetSenorModel.shared
    let createCsv = CreateCsv()
    
    override class func setUp() {
        GetSenorModel.shared.createMockDataLog()
    }
    
    func testCreateMotionCsv() {
        // createMotionCsv は time + 加速度3 + 角速度3 + 重力3 + 姿勢3 の13列を1つに出力する。
        let csv = "time, accelerationX, accelerationY, accelerationZ, rotationRateX, rotationRateY, rotationRateZ, gravityX, gravityY, gravityZ, pich, roll, yaw\n0.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0"
        XCTAssertEqual(createCsv.createMotionCsv(), csv)
    }

    func testCreateGpsCsv() {
        let csv = "elapsedTime, time, latitude, longitude\n0.0, 0, 1.0, 2.0"
        XCTAssertEqual(createCsv.createGpsCsv(), csv)
    }
    
    override class func tearDown() {
        GetSenorModel.shared.initializeSensorData()
    }
}
