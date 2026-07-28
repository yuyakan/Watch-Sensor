//
//  ReviewRequester.swift
//  WatchSensor
//
//  App Store レビュー依頼のタイミングを制御する。
//  詳細画面（グラフ）を開いた回数で判定し、初回は3回目、以降は10回ごとに依頼する。
//  広告（エクスポート時のインタースティシャル）とアクションが分離した詳細表示直後に出す。
//  （実際に表示するかは iOS 側の頻度制限にも委ねられる）
//

import Foundation
import UIKit
import StoreKit

enum ReviewRequester {
    private static let detailOpenCountKey = "review.detailOpenCount"

    /// 最初にレビューを依頼する詳細表示回数。
    private static let firstRequestAt = 3
    /// 2回目以降の依頼間隔（firstRequestAt を起点に、この回数ごと）。
    private static let interval = 10

    /// 詳細画面が開かれたことを記録し、レビューを依頼すべきタイミングかどうかを返す。
    /// 3回目、13回目、23回目 … で true を返す。
    /// - Returns: レビュー依頼を表示してよいなら true。
    static func registerDetailOpenAndShouldRequest(defaults: UserDefaults = .standard) -> Bool {
        let count = defaults.integer(forKey: detailOpenCountKey) + 1
        defaults.set(count, forKey: detailOpenCountKey)

        // 3回目、その後は (count - 3) が interval の倍数のときに依頼。
        guard count >= firstRequestAt else { return false }
        return (count - firstRequestAt) % interval == 0
    }

    /// アクティブな UIWindowScene を明示的に渡してレビュー依頼を表示する。
    /// SwiftUI の @Environment(\.requestReview) は scene を見つけられず
    /// "Could not get scene to request a review" で失敗することがあるため、
    /// scene を自前で解決して SKStoreReviewController に渡す。
    static func requestReview() {
        guard let scene = activeWindowScene() else {
            print("review request skipped: no active window scene")
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }

    private static func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }
}
