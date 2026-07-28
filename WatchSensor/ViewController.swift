//
//  ViewController.swift
//  WatchSensor
//
//  （旧 UIKit の一覧画面を SwiftUI 化。ファイル名は互換のため維持）
//  保存済みセッションの読み込みと、Watch 受信時の一覧更新を担う。
//

import Foundation
import Combine
import CoreLocation

/// 一覧画面のデータソース。
/// Watch からの受信は WatchConnectivityManager が担い、
/// ここはその通知（lastReceivedAt）を監視して一覧をリロードする。
final class SessionListViewModel: NSObject, ObservableObject {

    @Published private(set) var sessions: [SessionRecord] = []

    private let store = RealmStore()
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }

        // Watch からファイルを受信・保存したら一覧を読み直す。
        WatchConnectivityManager.shared.$lastReceivedAt
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)

        reload()
    }

    /// Realm から最新のセッション一覧を読み直す。
    func reload() {
        let loaded = store.loadSessions()
        DispatchQueue.main.async {
            self.sessions = loaded
        }
    }

    /// スワイプ削除。sessionID 単位でまとめて消す（別テーブルを index で引かない）。
    func delete(_ session: SessionRecord) {
        store.deleteSession(id: session.id)
        reload()
    }
}
