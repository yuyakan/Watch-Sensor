//
//  GPSManager.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/03.
//

import WatchKit

class GPSManager: NSObject,CLLocationManagerDelegate{
    private var locationManager : CLLocationManager
    private var currentLocation: CLLocation!
    
    override init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        super.init()

        locationManager.delegate = self

        self.locationManager.requestAlwaysAuthorization()
        // allowsBackgroundLocationUpdates はここでは立てない。
        // Always 許可が下りていない状態で true にすると実機で警告/クラッシュしうるため、
        // 許可状態が確定してから locationManagerDidChangeAuthorization で設定する。
    }

    /// 権限状態が変わるたびに呼ばれる正しい delegate。
    /// （従来の `locationManager(manager:didChangeAuthorizationStatus:)` は
    ///  シグネチャが誤っていて一度も呼ばれていなかった）
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedAlways:
            // Always のときだけバックグラウンド計測を有効化する（手首を下ろしても継続）。
            manager.allowsBackgroundLocationUpdates = true
        case .authorizedWhenInUse, .denied, .restricted:
            // WhenInUse / 拒否 ではバックグラウンド更新を無効に保つ（クラッシュ回避）。
            manager.allowsBackgroundLocationUpdates = false
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
                  return
             }

        let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)

        let formatter: DateFormatter = DateFormatter()
        formatter.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: newLocation.timestamp)
        GetSenorModel.shared.appendGpsData(latitude: location.latitude, longitude: location.longitude, time: time)
    }
    
    func startUpdata() {
        self.locationManager.startUpdatingLocation()
    }
    
    func stopUpdate() {
        locationManager.stopUpdatingLocation()
    }
}
