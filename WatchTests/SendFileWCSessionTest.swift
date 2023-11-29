//
//  SendFileWCSessionTest.swift
//  WatchTests
//
//  Created by 上別縄祐也 on 2022/07/12.
//

import XCTest
@testable import Watch_WatchKit_Extension

class SendFileWCSessionTest: XCTestCase {
    
    let sendFileWCSession = SendFileWCSession()

    func testMakeDirName(){
        XCTContext.runActivity(named: "月、日、時間が2桁の場合") { _ in
            let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2020, month: 11, day: 10, hour: 12, minute: 34, second: 56))!
            XCTAssertEqual(sendFileWCSession.makeDirName(date: date), "[11_10]12-34-56")
        }
        
        XCTContext.runActivity(named: "月、日、時間が1桁の場合") { _ in
            let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2020, month: 1, day: 2, hour: 1, minute: 2, second: 3))!
            XCTAssertEqual(sendFileWCSession.makeDirName(date: date), "[01_02]01-02-03")
        }
    }
    
    func testSendFile(){
        XCTAssertTrue(sendFileWCSession.sendFile())
    }
    
    func testSendMotionFile(){
        XCTAssertTrue(sendFileWCSession.sendMotionFile(directoryName: "directoryName"))
    }
    
    func testSendGpsFile(){
        XCTAssertTrue(sendFileWCSession.sendGpsFile(directoryName: "directoryName"))
    }
    
    func testSendGravityAndAttitudeFile(){
        XCTAssertTrue(sendFileWCSession.sendGravityAndAttitudeFile(directoryName: "directory"))
    }
    

}
