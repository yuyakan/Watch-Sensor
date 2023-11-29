//
//  GpsInfo.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/05.
//

import Foundation
import RealmSwift

class GpsInfo: Object {
   @objc dynamic var fileName: String = ""
   @objc dynamic var fileContents: String = ""
}
