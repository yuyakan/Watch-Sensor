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
        dataLog = allData(timeStamp: [0], accelerationData: sensorData(name: "acceleration", X: [1], Y: [2], Z: [3]),
                          rotationData:sensorData(name: "rotation", X: [1], Y: [2], Z: [3]),
                          gpsData: gpsData(gpsTimeStamp: ["0"], latitude: [1], longitude: [2]),
                          gravityData: sensorData(name: "gravity", X: [1], Y: [2], Z: [3]),
                          atitudeData: sensorData(name: "attitude", X: [1], Y: [2], Z: [3]))
    }
}

class CreateCSVTest: XCTestCase {
    let getSensorModel = GetSenorModel.shared
    let createCsv = CreateCsv()
    
    override class func setUp() {
        GetSenorModel.shared.createMockDataLog()
    }
    
    func testCreateMotionCsv() {
        let csv = "time, accelerationX, accelerationY, accelerationZ, rotationRateX, rotationRateY, rotationRateZ\n0.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0"
        XCTAssertEqual(createCsv.createMotionCsv(), csv)
    }
    
    func testCreateGpsCsv() {
        let csv = "time, latitude, longitude\n0, 1.0, 2.0"
        XCTAssertEqual(createCsv.createGpsCsv(), csv)
    }
    
    func testCreateGravityAndAttitudeCsv() {
        let csv = "time, gravityX, gravityY, gravityZ, pich, roll, yaw\n0.0, 1.0, 2.0, 3.0, 1.0, 2.0, 3.0"
        XCTAssertEqual(createCsv.crateGravityAndAttitudeCsv(), csv)
    }
    
    override class func tearDown() {
        GetSenorModel.shared.initializeSensorData()
    }
}
