//
//  WCSession.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/07/03.
//

import WatchKit
import WatchConnectivity

class SendFileWCSession: NSObject, WCSessionDelegate {
    var crateCsv = CreateCsv()
    private let session: WCSession

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
    
    func sendFile() -> Bool {
        let directoryName = makeDirName(date: Date())
        
        let isMotionFileSended = sendMotionFile(directoryName: directoryName)
        let isGpsFileSended = sendGpsFile(directoryName: directoryName)
        let isGravityAndAttitudeFileSended = sendGravityAndAttitudeFile(directoryName: directoryName)
        
        return isMotionFileSended && isGpsFileSended && isGravityAndAttitudeFileSended
    }
    
    private func makeDirName(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "[MM_dd]HH-mm-ss"
        let fileName = dateFormatter.string(from: date)
        return fileName
    }
    
    private func sendMotionFile(directoryName: String) -> Bool {
        let csv = crateCsv.createMotionCsv()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "Motion.csv"
        
        let url = tempDirectory.appendingPathComponent(fileName)
        let message = ["title": directoryName, "file": fileName, "tag": "motion"]
        
        do {
            try csv.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            WCSession.default.transferFile(url, metadata: message)
            session.transferFile(url, metadata: message)
            print(url)
        } catch {
            return false
        }
        return true
    }
    
    private func sendGpsFile(directoryName: String) -> Bool {
        let csv = crateCsv.createGpsCsv()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        
        let fileName = "GPS.csv"
        
        let url = tempDirectory.appendingPathComponent(fileName)
        let message = ["title": directoryName, "file": fileName, "tag": "gps"]
        
        do {
            try csv.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            WCSession.default.transferFile(url, metadata: message)
            session.transferFile(url, metadata: message)
        } catch {
            return false
        }
        return true
    }
    
    private func sendGravityAndAttitudeFile(directoryName: String) -> Bool {
        let csv = crateCsv.crateGravityAndAttitudeCsv()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "GravityAndAttitude.csv"
        
        let url = tempDirectory.appendingPathComponent(fileName)
        let message = ["title": directoryName, "file": fileName, "tag": "g_and_a"]
        
        do {
            try csv.write(to: url, atomically: true, encoding: String.Encoding.utf8)
//            WCSession.default.transferFile(url, metadata: message)
            session.transferFile(url, metadata: message)
        } catch {
            return false
        }
        return true
    }
}
