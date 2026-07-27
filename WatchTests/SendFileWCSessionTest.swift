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
        // makeDirName は端末のローカルタイムゾーンで整形するため、
        // テストも同じカレンダー/タイムゾーンで基準日時を作って比較する。
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        XCTContext.runActivity(named: "月、日、時間が2桁の場合") { _ in
            let date = calendar.date(from: DateComponents(year: 2020, month: 11, day: 10, hour: 12, minute: 34, second: 56))!
            XCTAssertEqual(sendFileWCSession.makeDirName(date: date), "2020-11-10_12-34-56")
        }

        XCTContext.runActivity(named: "月、日、時間が1桁の場合（ゼロ埋め）") { _ in
            let date = calendar.date(from: DateComponents(year: 2020, month: 1, day: 2, hour: 1, minute: 2, second: 3))!
            XCTAssertEqual(sendFileWCSession.makeDirName(date: date), "2020-01-02_01-02-03")
        }
    }
}
