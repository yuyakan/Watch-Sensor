//
//  InterfaceController.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/06/27.
//

import WatchKit
import Combine

class InterfaceController: WKInterfaceController {
    private var subscriptions = Set<AnyCancellable>()
    var getSensorModel = GetSenorModel.shared
    var sendFileWCSession = SendFileWCSession()
    var gpsManager = GPSManager()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        sendFileWCSession.wCSessionSetting()
        getSensorModel.checkMotionActive()
        
        getSensorModel.$displyTime.sink { time in
            self.TimeLabel.setText(time)
        }.store(in: &subscriptions)
        
        StopButtonOutlet.setEnabled(false)
        SaveButtonOutlet.setEnabled(false)
    }
  
    @IBOutlet weak var TimeLabel: WKInterfaceLabel!
    
    @IBOutlet weak var StartButtonOutlet: WKInterfaceButton!
    @IBOutlet weak var StopButtonOutlet: WKInterfaceButton!
    @IBOutlet weak var SaveButtonOutlet: WKInterfaceButton!
    
    
    @IBAction func StartButton() {
        StopButtonOutlet.setEnabled(true)
        getSensorModel.initializeSensorData()
        gpsManager.startUpdata()
        getSensorModel.startGetMotionData()
    }
    
    @IBAction func StopButton() {
        StopButtonOutlet.setEnabled(false)
        SaveButtonOutlet.setEnabled(true)
        getSensorModel.stopGetMotionData()
        gpsManager.stopUpdate()
    }
    
    @IBAction func SaveButton() {
        
        SaveButtonOutlet.setEnabled(false)
        let isFileSended = sendFileWCSession.sendFile()
        
        if isFileSended {
            let saveAction = WKAlertAction.init(title: "OK",
                                                  style: .default,
                                                  handler: {
                                                    print("save complete")
            })
            self.presentAlert(withTitle: "Save complete",
                              message: "",
                              preferredStyle: .alert,
                              actions: [saveAction])
            
            TimeLabel.setText("0.00")
        }
    }
}

