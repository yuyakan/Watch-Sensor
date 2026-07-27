//
//  DirectoryInfo.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/05.
//

import Foundation
import RealmSwift

class DirectoryInfo: Object {
    /// 1回の計測セッションを一意に識別するキー。
    /// SensorInfo / GpsInfo と同じ値で紐付け、到着順やインデックスに依存せず対応関係を保つ。
    @objc dynamic var sessionID: String = UUID().uuidString
    @objc dynamic var directoryName: String = ""
    /// 一覧の並び順を安定させるための作成日時。
    @objc dynamic var createdAt: Date = Date()

    override static func primaryKey() -> String? {
        return "sessionID"
    }
}
