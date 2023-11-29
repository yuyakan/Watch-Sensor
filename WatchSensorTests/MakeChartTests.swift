//
//  MakeChartTests.swift
//  WatchSensorTests
//
//  Created by 上別縄祐也 on 2022/07/15.
//

import XCTest
@testable import WatchSensor

class MakeChartTests: XCTestCase {
    
    let makeChart = MakeChart()

    func testMakeGraphData() {
        let labelsSeparate: [String] = ["t", " x", " y", " z", " x", " y", " z"]
        let data: [[Double]] = [[1.0], [2.0], [3.0], [4.0], [5.0], [6.0], [7.0]]
        
        let result = makeChart.makeGraphData(sensorInfo: FileInfo.mock1.sensorInfo[1])
        XCTAssertEqual(result.data, data)
        XCTAssertEqual(result.labels, labelsSeparate)
    }

}
