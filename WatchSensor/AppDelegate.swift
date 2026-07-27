//
//  AppDelegate.swift
//  WatchSensor
//
//  SwiftUI App エントリポイント。（旧 UIKit AppDelegate + Storyboard 構成を置換）
//

import SwiftUI
import GoogleMobileAds

@main
struct WatchSensorApp: App {
    init() {
        // Realm 設定・マイグレーションを起動時に一度だけ適用する。
        RealmStore.configure()
        // Watch からの受信を、画面表示より前に待ち受け開始する（取りこぼし防止）。
        WatchConnectivityManager.shared.start()
        // Google Mobile Ads 初期化。
        MobileAds.shared.start(completionHandler: nil)

        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        // シミュレータ確認用: 環境変数が立っているときだけサンプルデータを投入する。
        if env["SEED_SAMPLE_DATA"] == "1" {
            RealmStore().seedSampleDataIfNeeded()
        }
        // シミュレータ検証用: Watch から届いたのと同じ受信経路を擬似発火する。
        if env["SIMULATE_WATCH_RECEIVE"] == "1" {
            WatchConnectivityManager.shared.simulateReceiveFromWatch()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            SessionListView()
        }
    }
}
