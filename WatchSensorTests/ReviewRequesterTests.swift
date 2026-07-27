//
//  ReviewRequesterTests.swift
//  WatchSensorTests
//
//  レビュー依頼の頻度ロジック（初回3回目、以降10回ごと）を検証する。
//

import XCTest
@testable import WatchSensor

final class ReviewRequesterTests: XCTestCase {

    /// テストごとに独立した UserDefaults を使う（本番の設定を汚さない）。
    private func makeDefaults() -> UserDefaults {
        let suite = "ReviewRequesterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    /// 1〜30回目のうち、true を返すのは 3, 13, 23 回目だけ。
    func testRequestsAtThirdThenEveryTen() {
        let defaults = makeDefaults()
        var trueAt: [Int] = []
        for open in 1...30 {
            if ReviewRequester.registerDetailOpenAndShouldRequest(defaults: defaults) {
                trueAt.append(open)
            }
        }
        XCTAssertEqual(trueAt, [3, 13, 23])
    }

    /// 3回目より前は一度も依頼しない。
    func testNoRequestBeforeThird() {
        let defaults = makeDefaults()
        XCTAssertFalse(ReviewRequester.registerDetailOpenAndShouldRequest(defaults: defaults)) // 1
        XCTAssertFalse(ReviewRequester.registerDetailOpenAndShouldRequest(defaults: defaults)) // 2
        XCTAssertTrue(ReviewRequester.registerDetailOpenAndShouldRequest(defaults: defaults))  // 3
    }
}
