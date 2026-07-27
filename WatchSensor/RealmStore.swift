//
//  RealmStore.swift
//  WatchSensor
//
//  Realm の設定・マイグレーション・計測データの読み書きを一元管理する。
//  UI 層（SwiftUI）はこの Store 越しにのみ Realm へアクセスし、
//  「到着順・インデックスに依存した別テーブル参照」という従来の不具合を排除する。
//

import Foundation
import RealmSwift

/// 一覧・詳細画面で扱う、1セッション分のまとまったデータ。
struct SessionRecord: Identifiable {
    let id: String            // sessionID
    let directoryName: String
    let createdAt: Date

    /// エクスポート・グラフ描画に渡す FileInfo 形式。
    let fileInfo: FileInfo
}

/// Realm への唯一のアクセス経路。
final class RealmStore {

    /// スキーマバージョン。sessionID / createdAt 追加のため 0 → 1 に更新。
    static let schemaVersion: UInt64 = 1

    static func configure() {
        var config = Realm.Configuration()
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let realmURL = libraryURL.appendingPathComponent("MyRealm.realm")
        config.fileURL = realmURL
        config.schemaVersion = schemaVersion
        config.migrationBlock = { migration, oldSchemaVersion in
            guard oldSchemaVersion < 1 else { return }
            // 旧データは sessionID を持たない。3テーブルは同じ順序で追加されていた前提なので、
            // 通し番号から決定的な sessionID を割り当てて対応関係を復元する。
            assignSessionIDs(to: DirectoryInfo.className(), in: migration)
            assignSessionIDs(to: SensorInfo.className(), in: migration)
            assignSessionIDs(to: GpsInfo.className(), in: migration)
        }
        Realm.Configuration.defaultConfiguration = config
    }

    /// 旧レコードに `session-<index>` 形式の決定的な sessionID を付与する。
    private static func assignSessionIDs(to className: String, in migration: Migration) {
        var index = 0
        migration.enumerateObjects(ofType: className) { _, newObject in
            newObject?["sessionID"] = "legacy-session-\(index)"
            if className == DirectoryInfo.className() {
                newObject?["createdAt"] = Date(timeIntervalSince1970: 0)
            }
            index += 1
        }
    }

    /// テスト時に in-memory などの設定を差し込むための任意 Configuration。
    /// nil の場合は `configure()` で設定した defaultConfiguration を使う（本番挙動）。
    private let configuration: Realm.Configuration?

    init(configuration: Realm.Configuration? = nil) {
        self.configuration = configuration
    }

    #if DEBUG
    /// テスト用: プロセス内だけで完結する in-memory ストアを作る。
    /// これによりテストは RealmSwift を直接 import せずに独立した Realm を得られる。
    static func inMemoryStore(identifier: String = UUID().uuidString) -> RealmStore {
        var config = Realm.Configuration(inMemoryIdentifier: identifier)
        config.schemaVersion = schemaVersion
        return RealmStore(configuration: config)
    }
    #endif

    private func makeRealm() throws -> Realm {
        if let configuration {
            return try Realm(configuration: configuration)
        }
        return try Realm()
    }

    // MARK: - Read

    /// 保存済みセッションを新しい順で取得する。
    /// Directory を主として、同じ sessionID の Sensor / GPS を突き合わせる。
    func loadSessions() -> [SessionRecord] {
        guard let realm = try? makeRealm() else { return [] }

        let directories = realm.objects(DirectoryInfo.self)
            .sorted(byKeyPath: "createdAt", ascending: false)

        return directories.map { dir in
            let sensor = realm.object(ofType: SensorInfo.self, forPrimaryKey: dir.sessionID)
            let gps = realm.object(ofType: GpsInfo.self, forPrimaryKey: dir.sessionID)

            let fileInfo = FileInfo(
                sensorInfo: [sensor?.fileName ?? "", sensor?.fileContents ?? ""],
                gpsInfo: [gps?.fileName ?? "", gps?.fileContents ?? ""],
                directoryInfo: dir.directoryName
            )
            return SessionRecord(
                id: dir.sessionID,
                directoryName: dir.directoryName,
                createdAt: dir.createdAt,
                fileInfo: fileInfo
            )
        }
    }

    // MARK: - Write (Watch からの受信)

    /// Watch から届いた motion / gps ファイルを保存する。
    /// 到着順に依存せず、同じ directoryName（= 1計測）を同一 sessionID にまとめる。
    ///
    /// - Returns: 保存に成功したら true。
    @discardableResult
    func store(directoryName: String, fileName: String, fileContents: String, tag: String) -> Bool {
        guard let realm = try? makeRealm() else { return false }

        // 同じ計測（directoryName）の DirectoryInfo が既にあればその sessionID を使い、
        // なければ新規セッションを作る。これで motion / gps どちらが先に届いても正しく紐付く。
        let existing = realm.objects(DirectoryInfo.self)
            .filter("directoryName == %@", directoryName).first
        let sessionID = existing?.sessionID ?? UUID().uuidString

        do {
            try realm.write {
                if existing == nil {
                    let dir = DirectoryInfo()
                    dir.sessionID = sessionID
                    dir.directoryName = directoryName
                    dir.createdAt = Date()
                    realm.add(dir)
                }

                if tag == "gps" {
                    let gps = GpsInfo()
                    gps.sessionID = sessionID
                    gps.fileName = fileName
                    gps.fileContents = fileContents
                    realm.add(gps, update: .modified)
                } else {
                    let sensor = SensorInfo()
                    sensor.sessionID = sessionID
                    sensor.fileName = fileName
                    sensor.fileContents = fileContents
                    realm.add(sensor, update: .modified)
                }
            }
        } catch {
            print("Realm write failed: \(error)")
            return false
        }
        return true
    }

    // MARK: - Delete

    /// sessionID に紐づく Directory / Sensor / GPS をまとめて削除する。
    func deleteSession(id sessionID: String) {
        guard let realm = try? makeRealm() else { return }
        do {
            try realm.write {
                if let dir = realm.object(ofType: DirectoryInfo.self, forPrimaryKey: sessionID) {
                    realm.delete(dir)
                }
                if let sensor = realm.object(ofType: SensorInfo.self, forPrimaryKey: sessionID) {
                    realm.delete(sensor)
                }
                if let gps = realm.object(ofType: GpsInfo.self, forPrimaryKey: sessionID) {
                    realm.delete(gps)
                }
            }
        } catch {
            print("Realm delete failed: \(error)")
        }
    }

#if DEBUG
    // MARK: - Debug sample data

    /// シミュレータ確認用のサンプルセッションを1件投入する。
    /// 既存の store() 経路を通すので本番と同じ紐付けロジックで登録される。
    /// 環境変数 SEED_SAMPLE_DATA=1 のときだけ AppDelegate から呼ばれる。
    func seedSampleDataIfNeeded() {
        let directoryName = "Sample-2026-07-26_10-00-00"
        // 既に投入済みなら二重登録しない。
        if let realm = try? makeRealm(),
           realm.objects(DirectoryInfo.self).filter("directoryName == %@", directoryName).first != nil {
            return
        }

        // 正弦波ベースのサンプル motion CSV（13列: time + 4センサー×3軸）。
        var motion = "time, accelerationX, accelerationY, accelerationZ, rotationRateX, rotationRateY, rotationRateZ, gravityX, gravityY, gravityZ, pich, roll, yaw\n"
        for i in 0..<120 {
            let t = Double(i) * 0.05
            let s = sin(t * 2)
            let c = cos(t * 2)
            let row = [t,
                       s, c, s * 0.5,
                       c, s, c * 0.5,
                       0.1 * s, -0.9 + 0.1 * c, 0.2 * s,
                       s * 0.3, c * 0.3, s * 0.1]
                .map { String(format: "%.4f", $0) }
                .joined(separator: ", ")
            motion += row + "\n"
        }

        var gps = "time, latitude, longitude\n"
        for i in 0..<20 {
            let lat = 35.6812 + Double(i) * 0.0001
            let lon = 139.7671 + Double(i) * 0.0001
            gps += String(format: "10:%02d:00, %.6f, %.6f\n", i, lat, lon)
        }

        store(directoryName: directoryName, fileName: "Motion.csv", fileContents: motion, tag: "motion")
        store(directoryName: directoryName, fileName: "GPS.csv", fileContents: gps, tag: "gps")
    }
#endif
}
