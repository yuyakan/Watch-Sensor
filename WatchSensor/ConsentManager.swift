//
//  ConsentManager.swift
//  WatchSensor
//
//  パーソナライズ広告のための同意フローを管理する。
//  UMP（User Messaging Platform）で GDPR 等の同意フォームを出し、
//  続けて ATT（App Tracking Transparency）を要求してから広告 SDK を初期化する。
//
//  正しい順序: UMP 同意 → ATT リクエスト → GoogleMobileAds 初期化
//

import Foundation
import UserMessagingPlatform
import AppTrackingTransparency
import AdSupport
import GoogleMobileAds

final class ConsentManager {

    static let shared = ConsentManager()
    private init() {}

    /// アプリ起動時に一度呼ぶ。同意フロー完了後に広告 SDK を初期化する。
    func gatherConsentAndStartAds() {
        // スクリーンショット撮影時などは同意フロー・広告初期化ごとスキップする。
        guard !AdsConfig.isHidden else { return }

        let parameters = RequestParameters()
        // 本番リリース時は false（未成年者向け扱いにしない）。必要に応じて調整。
        parameters.isTaggedForUnderAgeOfConsent = false

        // UMP の同意情報を最新化する。
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self else { return }
            if let error {
                print("UMP consent info update failed: \(error.localizedDescription)")
                // 同意情報の取得に失敗しても、ATT だけは要求して広告は初期化する。
                self.requestATTThenStartAds()
                return
            }

            // 必要なら同意フォームを表示する（対象地域でのみ実際に出る）。
            self.loadAndPresentConsentFormIfNeeded {
                // UMP 完了後に ATT → 広告初期化。
                self.requestATTThenStartAds()
            }
        }
    }

    /// 同意フォームが必要なら読み込んで表示する。不要ならそのまま completion。
    private func loadAndPresentConsentFormIfNeeded(completion: @escaping () -> Void) {
        guard let root = Self.rootViewController() else {
            completion()
            return
        }
        ConsentForm.loadAndPresentIfRequired(from: root) { error in
            if let error {
                print("UMP consent form error: \(error.localizedDescription)")
            }
            completion()
        }
    }

    /// ATT を要求してから広告 SDK を初期化する。
    /// ATT は必ずメインスレッド、かつアプリが active な状態で呼ぶ。
    private func requestATTThenStartAds() {
        DispatchQueue.main.async {
            ATTrackingManager.requestTrackingAuthorization { _ in
                // 許可/拒否いずれでも広告自体は出す（拒否ならパーソナライズされないだけ）。
                DispatchQueue.main.async {
                    MobileAds.shared.start(completionHandler: nil)
                }
            }
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first(where: { $0.isKeyWindow })?.rootViewController
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
    }
}
