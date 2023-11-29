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
        
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
    }
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status:CLAuthorizationStatus) {
            if (status == .notDetermined) {
                if(self.locationManager.responds(to:#selector(CLLocationManager.requestAlwaysAuthorization))) {
                    self.locationManager.requestAlwaysAuthorization()
                }
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
