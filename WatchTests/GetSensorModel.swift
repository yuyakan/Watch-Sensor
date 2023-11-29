//
//  GetSensorModel.swift
//  WatchTests
//
//  Created by 上別縄祐也 on 2022/07/19.
//

import XCTest
import CoreMotion
@testable import Watch_WatchKit_Extension

class GetSensorModel: XCTestCase {
    let getSensorModel = GetSenorModel.shared

    override class func setUp() {
        CMAcceleration.mock1
        super.setUp()
    }

   
}
