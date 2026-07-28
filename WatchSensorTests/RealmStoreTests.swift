//
//  RealmStoreTests.swift
//  WatchSensorTests
//
//  iPhone 側の受信ロジック（Watch から届いた motion / gps を Realm に保存し、
//  1セッションに正しく紐づける）を、実機なしで擬似的に検証する。
//  ここは WCSession.didReceive から呼ばれる本番コード（RealmStore.store）そのもの。
//

import XCTest
@testable import WatchSensor

final class RealmStoreTests: XCTestCase {

    /// テストごとに独立した in-memory Realm を使い、本番データを汚さない。
    private func makeStore(id: String = UUID().uuidString) -> RealmStore {
        RealmStore.inMemoryStore(identifier: id)
    }

    private let motionCSV = "time, accelerationX\n0.0, 1.0\n0.1, 2.0"
    private let gpsCSV = "time, latitude, longitude\n10:00:00, 35.0, 139.0"

    /// motion → gps の順で届いた場合、1セッションにまとまる。
    func testMotionThenGps_makesSingleSession() {
        let store = makeStore()
        let dir = "2026-07-26_10-00-00"

        store.store(directoryName: dir, fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")
        store.store(directoryName: dir, fileName: "GPS.csv", fileContents: gpsCSV, tag: "gps")

        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 1, "1計測は1セッションになるべき")
        XCTAssertEqual(sessions[0].directoryName, dir)
        XCTAssertEqual(sessions[0].fileInfo.sensorInfo[0], "Motion.csv")
        XCTAssertEqual(sessions[0].fileInfo.gpsInfo[0], "GPS.csv")
        XCTAssertFalse(sessions[0].fileInfo.sensorInfo[1].isEmpty, "motion 本文が紐づくべき")
        XCTAssertFalse(sessions[0].fileInfo.gpsInfo[1].isEmpty, "gps 本文が紐づくべき")
    }

    /// gps → motion の順（到着順が逆）でも、同じ1セッションにまとまる。
    /// これが従来クラッシュ/ズレを起こしていたケース（不具合#1）。
    func testGpsThenMotion_stillSingleSession() {
        let store = makeStore()
        let dir = "2026-07-26_11-00-00"

        // わざと GPS を先に受信させる。
        store.store(directoryName: dir, fileName: "GPS.csv", fileContents: gpsCSV, tag: "gps")
        store.store(directoryName: dir, fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")

        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 1, "到着順が逆でも1セッションに紐づくべき")
        XCTAssertEqual(sessions[0].fileInfo.sensorInfo[0], "Motion.csv")
        XCTAssertEqual(sessions[0].fileInfo.gpsInfo[0], "GPS.csv")
    }

    /// 別々の計測（directoryName 違い）は別セッションとして扱われ、混ざらない。
    func testDifferentMeasurements_areSeparateSessions() {
        let store = makeStore()

        store.store(directoryName: "A", fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")
        store.store(directoryName: "A", fileName: "GPS.csv", fileContents: gpsCSV, tag: "gps")
        store.store(directoryName: "B", fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")
        store.store(directoryName: "B", fileName: "GPS.csv", fileContents: gpsCSV, tag: "gps")

        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(Set(sessions.map { $0.directoryName }), ["A", "B"])
    }

    /// 削除は sessionID 単位で Directory / Sensor / GPS をまとめて消す。
    func testDeleteSession_removesAllRelated() {
        let store = makeStore()
        let dir = "2026-07-26_12-00-00"
        store.store(directoryName: dir, fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")
        store.store(directoryName: dir, fileName: "GPS.csv", fileContents: gpsCSV, tag: "gps")

        var sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 1)

        store.deleteSession(id: sessions[0].id)

        sessions = store.loadSessions()
        XCTAssertTrue(sessions.isEmpty, "削除後は空になるべき")
    }

    /// 新しい計測ほど上（新しい順）に並ぶ。
    func testSessions_sortedByNewestFirst() {
        let store = makeStore()
        store.store(directoryName: "old", fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")
        // createdAt が Date() 依存のため、確実に差をつける。
        Thread.sleep(forTimeInterval: 0.01)
        store.store(directoryName: "new", fileName: "Motion.csv", fileContents: motionCSV, tag: "motion")

        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.first?.directoryName, "new", "新しい計測が先頭に来るべき")
    }
}
