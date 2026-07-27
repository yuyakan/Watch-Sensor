//
//  WCSession.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/03.
//

import WatchKit
import WatchConnectivity

/// センサー CSV を iPhone へ送るクラス。
/// transferFile は非同期のバックグラウンド転送なので、`didFinish` で
/// 実際の転送完了（またはエラー）を待ってから結果を返す。
class SendFileWCSession: NSObject, WCSessionDelegate {
    var crateCsv = CreateCsv()
    private let session: WCSession

    /// 送信中のファイル転送と、その完了を集約するための状態。
    private var pendingTransfers: [WCSessionFileTransfer] = []
    private var completion: ((Result<Void, Error>) -> Void)?
    private var firstError: Error?

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        self.session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            print("The session has completed activation.")
        }
    }

    func wCSessionSetting() {
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// motion / gps の2ファイルを送信し、両方の転送完了（またはいずれかの失敗）で completion を呼ぶ。
    /// CSV の書き込み自体に失敗した場合も failure を返す。
    func sendFile(completion: @escaping (Result<Void, Error>) -> Void) {
        let directoryName = makeDirName(date: Date())

        // 二重送信を防ぐ。前の送信が完了していない場合は弾く。
        guard self.completion == nil else {
            completion(.failure(SendError.busy))
            return
        }

        do {
            let motionTransfer = try startTransfer(csv: crateCsv.createMotionCsv(),
                                                   fileName: "Motion.csv",
                                                   tag: "motion",
                                                   directoryName: directoryName)
            let gpsTransfer = try startTransfer(csv: crateCsv.createGpsCsv(),
                                                fileName: "GPS.csv",
                                                tag: "gps",
                                                directoryName: directoryName)
            self.completion = completion
            self.firstError = nil
            self.pendingTransfers = [motionTransfer, gpsTransfer]
        } catch {
            // CSV 書き込み失敗などはこの場で失敗として返す。
            completion(.failure(error))
        }
    }

    private enum SendError: Error {
        case busy
    }

    // テストから検証できるよう internal にしている。
    func makeDirName(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = dateFormatter.string(from: date)
        return fileName
    }

    /// CSV を一時ファイルに書き出し、転送を開始して WCSessionFileTransfer を返す。
    private func startTransfer(csv: String, fileName: String, tag: String, directoryName: String) throws -> WCSessionFileTransfer {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let metadata = ["title": directoryName, "file": fileName, "tag": tag]
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return session.transferFile(url, metadata: metadata)
    }

    // MARK: - Transfer completion

    /// 各ファイル転送の完了で呼ばれる。2件そろったら completion を1回だけ呼ぶ。
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error = error, firstError == nil {
            firstError = error
        }
        pendingTransfers.removeAll { $0 === fileTransfer }

        guard pendingTransfers.isEmpty, let completion = self.completion else { return }
        self.completion = nil

        let result: Result<Void, Error> = firstError.map { .failure($0) } ?? .success(())
        firstError = nil
        // UI 更新につながるためメインスレッドで返す。
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
