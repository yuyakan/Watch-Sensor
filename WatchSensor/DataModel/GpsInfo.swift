//
//  GpsInfo.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/05.
//

import Foundation
import RealmSwift

class GpsInfo: Object {
    /// 対応する DirectoryInfo と同じセッションID。
    @objc dynamic var sessionID: String = ""
    @objc dynamic var fileName: String = ""
    @objc dynamic var fileContents: String = ""

    override static func primaryKey() -> String? {
        return "sessionID"
    }
}
