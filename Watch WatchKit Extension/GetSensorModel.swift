//
//  GetSensorModel.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/01.
//

import CoreMotion
import CoreLocation

protocol GetSensorModelPrivateProtocol {
    
}

final public class GetSenorModel {
    @Published var displayTime = "0.00"
    var nowTime: Double = 0.0
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    public static let shared = GetSenorModel()
    private init() {}
    
    var dataLog = allData(timeStamp: [], accelerationData: sensorData(name: "acceleration", X: [], Y: [], Z: []),
                          rotationData:sensorData(name: "rotation", X: [], Y: [], Z: []),
                          gpsData: gpsData(gpsTimeStamp: [], latitude: [], longitude: []),
                          gravityData: sensorData(name: "gravity", X: [], Y: [], Z: []),
                          atitudeData: sensorData(name: "attitude", X: [], Y: [], Z: []))
    
    func checkMotionActive(){
        if !motionManager.isDeviceMotionActive {
            print("Device Motion is not available.")
            return
        }
    }
    
    func initializeSensorData() {
        dataLog = allData(timeStamp: [], accelerationData: sensorData(name: "acceleration", X: [], Y: [], Z: []),
                          rotationData:sensorData(name: "rotation", X: [], Y: [], Z: []),
                          gpsData: gpsData(gpsTimeStamp: [], latitude: [], longitude: []),
                          gravityData: sensorData(name: "gravity", X: [], Y: [], Z: []),
                          atitudeData: sensorData(name: "attitude", X: [], Y: [], Z: []))
        
        nowTime = 0.0
    }
    
    func startGetMotionData() {
        motionManager.startDeviceMotionUpdates(to: queue) {[weak self] deviceMotion , error in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            guard let motion = deviceMotion else { return }
            self?.getData(motion)
        }
    }
    
    func getData(_ data: CMDeviceMotion){
        
        logingTime(time: data.timestamp)
        
        logingAcceleration(userAcceleration: data.userAcceleration)
        logingRotaitionRate(rotationRate: data.rotationRate)
        logingGravity(gravity: data.gravity)
        logingAttitude(attitude: data.attitude)
    }
    
    private func logingTime(time: TimeInterval) {
        if (nowTime == 0.0){
            nowTime = time
        }
     
        let elapsedTime = time - nowTime
        displayTime = String(format: "%.2f", elapsedTime)
        dataLog.timeStamp.append(elapsedTime)
    }
    
    private func logingAcceleration(userAcceleration: CMAcceleration) {
        dataLog.accelerationData.X.append(userAcceleration.x)
        dataLog.accelerationData.Y.append(userAcceleration.y)
        dataLog.accelerationData.Z.append(userAcceleration.z)
    }
    
    private func logingRotaitionRate(rotationRate: CMRotationRate) {
        dataLog.rotationData.X.append(rotationRate.x)
        dataLog.rotationData.Y.append(rotationRate.y)
        dataLog.rotationData.Z.append(rotationRate.z)
    }
    
    private func logingGravity(gravity: CMAcceleration) {
        dataLog.gravityData.X.append(gravity.x)
        dataLog.gravityData.Y.append(gravity.y)
        dataLog.gravityData.Z.append(gravity.z)
    }
    
    private func logingAttitude(attitude: CMAttitude) {
        dataLog.atitudeData.X.append(attitude.pitch)
        dataLog.atitudeData.Y.append(attitude.roll)
        dataLog.atitudeData.Z.append(attitude.yaw)
    }
    
    
    func appendGpsData(latitude: Double, longitude: Double, time: String) {
        dataLog.gpsData.latitude.append(latitude)
        dataLog.gpsData.longitude.append(longitude)
        dataLog.gpsData.gpsTimeStamp.append(time)
    }
    
    func stopGetMotionData() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func getDataLog () -> allData {
        return dataLog
    }
}
