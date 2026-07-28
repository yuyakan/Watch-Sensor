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
    /// 最初のサンプルの timestamp（計測開始の基準時刻）。
    private var baseTime: Double = 0.0
    /// baseTime が設定済みか。`baseTime == 0.0` を未設定判定に使うと、
    /// 万一 timestamp が 0 のときに誤判定するため、明示フラグで管理する。
    private var hasBaseTime = false
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    public static let shared = GetSenorModel()
    private init() {}

    /// dataLog への読み書きを直列化する専用キュー。
    /// motion 更新（バックグラウンド OperationQueue）・GPS 更新（メインの CLLocationManager）・
    /// CSV 生成時の読み出しが同じ配列に同時アクセスしてクラッシュ/破損するのを防ぐ。
    private let dataQueue = DispatchQueue(label: "kanbe1365.WatchSensor.sensorDataLog")

    // dataLog はスレッド安全のため必ず dataQueue 経由でアクセスする（直接触らない）。
    private var dataLog = allData(timeStamp: [], accelerationData: sensorData(name: "acceleration", X: [], Y: [], Z: []),
                          rotationData:sensorData(name: "rotation", X: [], Y: [], Z: []),
                          gpsData: gpsData(gpsTimeStamp: [], elapsedTime: [], latitude: [], longitude: []),
                          gravityData: sensorData(name: "gravity", X: [], Y: [], Z: []),
                          atitudeData: sensorData(name: "attitude", X: [], Y: [], Z: []))
    
    /// DeviceMotion がこの端末で利用可能かを返す。
    /// （従来は isDeviceMotionActive を見ていたが、これは「今計測中か」であり
    ///  計測開始前は常に false になるため、可用性チェックとして機能していなかった）
    @discardableResult
    func checkMotionActive() -> Bool {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return false
        }
        return true
    }
    
    func initializeSensorData() {
        dataQueue.sync {
            dataLog = allData(timeStamp: [], accelerationData: sensorData(name: "acceleration", X: [], Y: [], Z: []),
                              rotationData:sensorData(name: "rotation", X: [], Y: [], Z: []),
                              gpsData: gpsData(gpsTimeStamp: [], elapsedTime: [], latitude: [], longitude: []),
                              gravityData: sensorData(name: "gravity", X: [], Y: [], Z: []),
                              atitudeData: sensorData(name: "attitude", X: [], Y: [], Z: []))
            baseTime = 0.0
            hasBaseTime = false
        }
    }
    
    func startGetMotionData() {
        #if targetEnvironment(simulator)
        // シミュレータには実センサー（DeviceMotion）が無い。
        // Start→Stop→Save→iPhone 送信のフローを確認できるよう擬似計測に切り替える。
        // 実機ビルドではこの分岐は一切コンパイルされない。
        startSimulatedMotion()
        return
        #else
        guard checkMotionActive() else { return }
        // サンプリング間隔を明示する。未設定だと 0.0（システム任せ）で更新がまばら・不定期になる。
        // Apple Watch の DeviceMotion は最大およそ 100Hz なので、最も細かい 0.01 秒（100Hz）を指定する。
        // （実センサーの更新頻度が上限になるため、これより短くしても頭打ちになる）
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdates(to: queue) {[weak self] deviceMotion , error in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            guard let motion = deviceMotion else { return }
            self?.getData(motion)
        }
        #endif
    }

    #if targetEnvironment(simulator)
    private var simulationTimer: Timer?
    private var simulationTick: Double = 0.0

    /// 実センサーの代わりに、正弦波ベースのサンプル DeviceMotion 相当の値を
    /// 既存のログ関数へ流し込む。データ構造・CSV 生成・転送は本番と同じ経路を通る。
    private func startSimulatedMotion() {
        simulationTick = 0.0
        // 本番の deviceMotionUpdateInterval（0.01秒 / 100Hz）に合わせる。
        let interval = 0.01
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            let t = self.simulationTick
            let s = sin(t * 2)
            let c = cos(t * 2)

            // 本番と同様に dataQueue へ直列化して書き込む。
            self.dataQueue.async {
                self.logingTimeForSimulation(time: t)
                self.logingAcceleration(userAcceleration: CMAcceleration(x: s, y: c, z: s * 0.5))
                self.logingRotaitionRate(rotationRate: CMRotationRate(x: c, y: s, z: c * 0.5))
                self.logingGravity(gravity: CMAcceleration(x: 0.1 * s, y: -0.9 + 0.1 * c, z: 0.2 * s))
                self.logingAttitudeForSimulation(pitch: s * 0.3, roll: c * 0.3, yaw: s * 0.1)
            }
            self.simulationTick += interval
        }
        RunLoop.main.add(timer, forMode: .common)
        simulationTimer = timer
    }

    /// 擬似計測用: 経過時間をそのまま記録する（実 timestamp を使わない）。dataQueue 上で呼ぶ。
    private func logingTimeForSimulation(time: Double) {
        dataLog.timeStamp.append(time)
        let formatted = String(format: "%.2f", time)
        DispatchQueue.main.async { self.displayTime = formatted }
    }

    /// 擬似計測用: CMAttitude を生成できないので pitch/roll/yaw を直接記録する。dataQueue 上で呼ぶ。
    private func logingAttitudeForSimulation(pitch: Double, roll: Double, yaw: Double) {
        dataLog.atitudeData.X.append(pitch)
        dataLog.atitudeData.Y.append(roll)
        dataLog.atitudeData.Z.append(yaw)
    }
    #endif
    
    func getData(_ data: CMDeviceMotion){
        // motion コールバックはバックグラウンドスレッド。dataLog への書き込みは
        // dataQueue に直列化し、他スレッド（GPS / CSV 生成）との競合を避ける。
        dataQueue.async {
            self.logingTime(time: data.timestamp)
            self.logingAcceleration(userAcceleration: data.userAcceleration)
            self.logingRotaitionRate(rotationRate: data.rotationRate)
            self.logingGravity(gravity: data.gravity)
            self.logingAttitude(attitude: data.attitude)
        }
    }

    // 以降の loging* / appendGpsData は必ず dataQueue 上で呼ぶこと。

    private func logingTime(time: TimeInterval) {
        if !hasBaseTime {
            baseTime = time
            hasBaseTime = true
        }

        let elapsedTime = time - baseTime
        dataLog.timeStamp.append(elapsedTime)
        // @Published はメインスレッドで更新する（UI バインドのため）。
        let formatted = String(format: "%.2f", elapsedTime)
        DispatchQueue.main.async { self.displayTime = formatted }
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
        // motion の timestamp と同じ systemUptime 軸で現在時刻を取り、
        // 計測開始（baseTime）からの相対経過秒を求める。これで GPS と motion を
        // 同じ時間軸で突き合わせできる。呼び出し時点の値を先に取ってから直列化する。
        let uptime = ProcessInfo.processInfo.systemUptime
        // GPS コールバックはメインスレッド。dataLog は dataQueue に直列化する。
        dataQueue.async {
            let elapsed = self.hasBaseTime ? (uptime - self.baseTime) : 0.0
            self.dataLog.gpsData.elapsedTime.append(elapsed)
            self.dataLog.gpsData.latitude.append(latitude)
            self.dataLog.gpsData.longitude.append(longitude)
            self.dataLog.gpsData.gpsTimeStamp.append(time)
        }
    }

    func stopGetMotionData() {
        motionManager.stopDeviceMotionUpdates()
        #if targetEnvironment(simulator)
        simulationTimer?.invalidate()
        simulationTimer = nil
        #endif
    }

    func getDataLog () -> allData {
        // dataQueue.sync で、書き込み中でない一貫したスナップショットを取得する。
        // allData は値型（struct）なので、返した後に内部が書き換わる心配はない。
        // これにより「stop 直後に save」で走り残りの append と読み出しが競合する問題も防ぐ。
        return dataQueue.sync { dataLog }
    }

    /// テスト専用: dataLog を差し替える（dataQueue 経由で安全に設定）。
    /// dataLog を private にしたため、テストはこの入口を使う。
    func setDataLogForTesting(_ newValue: allData) {
        dataQueue.sync { dataLog = newValue }
    }
}
