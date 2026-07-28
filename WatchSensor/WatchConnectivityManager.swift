//
//  WatchConnectivityManager.swift
//  WatchSensor
//
//  Watch から届くセンサーファイルの受信を担うシングルトン。
//  アプリ起動時（WatchSensorApp.init）に activate しておき、
//  画面表示の有無に関わらず常に didReceive を受けられるようにする。
//  （従来は SwiftUI View の生成時に delegate 登録していたため、
//   起動直後に届いたファイルを取りこぼす可能性があった）
//

import Foundation
import Combine
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {

    static let shared = WatchConnectivityManager()

    /// 受信・保存が起きるたびに更新される。一覧はこれを監視してリロードする。
    @Published private(set) var lastReceivedAt: Date = .distantPast

    private let store = RealmStore()

    private override init() {
        super.init()
    }

    /// アプリ起動時に一度だけ呼ぶ。WCSession を activate し、delegate を張る。
    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    #if DEBUG
    /// シミュレータ検証用: Watch が送ったのと同じ2ファイル（motion / gps）を、
    /// 実際の受信経路（store）にそのまま流し込む。
    /// シミュレータの WatchConnectivity はペア間のファイル転送を配送しないため、
    /// iPhone 側の「受信→保存→一覧→グラフ」を実データで確認するために使う。
    /// あえて gps → motion の逆順で流し、到着順に依存しない紐付け（不具合#1修正）も実証する。
    func simulateReceiveFromWatch() {
        let directoryName = "WatchSim-\(Self.timestamp())"

        var motion = "time, accelerationX, accelerationY, accelerationZ, rotationRateX, rotationRateY, rotationRateZ, gravityX, gravityY, gravityZ, pich, roll, yaw\n"
        for i in 0..<120 {
            let t = Double(i) * 0.05
            let s = sin(t * 2), c = cos(t * 2)
            let row = [t, s, c, s * 0.5, c, s, c * 0.5, 0.1 * s, -0.9 + 0.1 * c, 0.2 * s, s * 0.3, c * 0.3, s * 0.1]
                .map { String(format: "%.4f", $0) }.joined(separator: ", ")
            motion += row + "\n"
        }
        var gps = "time, latitude, longitude\n"
        for i in 0..<20 {
            gps += String(format: "10:%02d:00, %.6f, %.6f\n", i, 35.6812 + Double(i) * 0.0001, 139.7671 + Double(i) * 0.0001)
        }

        // gps を先に受信させる（到着順が逆のケース）。
        store.store(directoryName: directoryName, fileName: "GPS.csv", fileContents: gps, tag: "gps")
        store.store(directoryName: directoryName, fileName: "Motion.csv", fileContents: motion, tag: "motion")

        DispatchQueue.main.async {
            self.lastReceivedAt = Date()
        }
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return f.string(from: Date())
    }
    #endif
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        } else {
            print("WCSession activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // 再アクティベートしておく（デバイス切替時など）。
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard
            let directoryName = file.metadata?["title"] as? String,
            let fileName = file.metadata?["file"] as? String,
            let tag = file.metadata?["tag"] as? String
        else {
            print("received file with missing metadata: \(String(describing: file.metadata))")
            return
        }
        // ファイルは delegate から戻ると削除されるため、この場で読み切る。
        let fileContents: String
        do {
            fileContents = try String(contentsOf: file.fileURL, encoding: .utf8)
        } catch {
            print("failed to read received file '\(fileName)': \(error.localizedDescription)")
            return
        }

        // 到着順に依存せず、directoryName を鍵に sessionID へ束ねて保存する。
        let saved = store.store(directoryName: directoryName,
                                fileName: fileName,
                                fileContents: fileContents,
                                tag: tag)
        guard saved else {
            // 保存に失敗した場合は一覧を更新しない（Watch 側は成功表示だが取り込めていない状態）。
            print("failed to store received file '\(fileName)' (dir: \(directoryName), tag: \(tag))")
            return
        }

        DispatchQueue.main.async {
            self.lastReceivedAt = Date()
        }
    }
}
