//
//  AdSupport.swift
//  WatchSensor
//
//  Google Mobile Ads を SwiftUI で扱うためのラッパー。
//  バナー（一覧下部）とインタースティシャル（エクスポート後）を提供する。
//  ※ 広告ユニット ID は本番用。DEBUG ビルドのみ Google 公式テスト ID を使う。
//

import SwiftUI
import GoogleMobileAds

enum AdUnit {
#if DEBUG
    /// テスト用バナー広告ユニット（Google 公式テスト ID）。
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    /// テスト用インタースティシャル広告ユニット（Google 公式テスト ID）。
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
#else
    /// 本番バナー広告ユニット。
    static let banner = "ca-app-pub-3155724310732667/8224548331"
    /// 本番インタースティシャル広告ユニット。
    static let interstitial = "ca-app-pub-3155724310732667/2486024548"
#endif
}

enum AdsConfig {
    /// App Store 用スクリーンショット撮影などで広告を一時的に隠すためのフラグ。
    /// 環境変数 HIDE_ADS=1 のときだけ true になる（本番ビルド・通常起動には影響しない）。
    static var isHidden: Bool {
        ProcessInfo.processInfo.environment["HIDE_ADS"] == "1"
    }
}

// MARK: - Banner

/// 一覧画面下部に表示するバナー広告。
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdUnit.banner
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController
    }
}

// MARK: - Interstitial

/// インタースティシャル広告の読み込み・表示を管理する。
/// エクスポート完了アラートの「OK」で表示し、閉じられたら次回のために再読込する。
/// 取得失敗時は指数バックオフ（2,4,8,16,32秒 / 最大5回）で再取得する。
final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    private var interstitial: InterstitialAd?
    private var retryCount = 0
    private let maxRetryCount = 5

    override init() {
        super.init()
        load()
    }

    func load() {
        // スクリーンショット撮影時などは広告を読み込まない。
        guard !AdsConfig.isHidden else { return }
        InterstitialAd.load(with: AdUnit.interstitial, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                self.retryLoad()
                return
            }
            self.retryCount = 0
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            print("success ad load")
        }
    }

    /// 表示可能なら表示する。表示したら次回のために再読込予約。
    func present() {
        // スクリーンショット撮影時などは全画面広告を出さない。
        guard !AdsConfig.isHidden else { return }
        guard let interstitial,
              let root = Self.rootViewController() else {
            // まだ読み込めていない場合は次回に備えて取得しておく。
            load()
            return
        }
        self.interstitial = nil
        interstitial.present(from: root)
    }

    private func retryLoad() {
        guard retryCount < maxRetryCount else {
            print("Interstitial ad load failed after \(maxRetryCount) retries. Giving up.")
            return
        }
        retryCount += 1
        let delay = pow(2.0, Double(retryCount))
        print("Retrying interstitial ad load (\(retryCount)/\(maxRetryCount)) in \(delay)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.load()
        }
    }

    // MARK: FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        retryCount = 0
        load()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad with error: \(error.localizedDescription)")
        retryCount = 0
        load()
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController
    }
}
