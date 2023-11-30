//
//  InterfaceController.swift
//  Watch WatchKit Extension
//
//  Created by 上別縄祐也 on 2022/06/27.
//

import WatchKit
import Combine

import SwiftUI

class InterfaceController : WKHostingController<HomeView> {
    override var body: HomeView {
        return HomeView()
    }
}

struct HomeView: View {
    @ObservedObject var homeViewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack() {
                Text(homeViewModel.displayTime)
                    .font(.largeTitle)
                    .padding(.vertical, 10)
                Button(action: {homeViewModel.start()}, label: {
                    Text("Start")
                })
                Button(action: {homeViewModel.stop()}, label: {
                    Text("Stop")
                })
                .disabled(homeViewModel.isStopButtonDisabled)
                .opacity(homeViewModel.isStopButtonDisabled ? 0.5 : 1)
                Button(action: {homeViewModel.save()}, label: {
                    Text("Save")
                })
                .disabled(homeViewModel.isSaveButtonDisabled)
                .opacity(homeViewModel.isSaveButtonDisabled ? 0.5 : 1)
            }
            .alert("Save complete", isPresented: $homeViewModel.isPresentedSaveCompleteAlert) {
                Button("OK") {homeViewModel.allInitialize()}
            }
        }
    }
}

class HomeViewModel: ObservableObject {
    @Published var isStopButtonDisabled = true
    @Published var isSaveButtonDisabled = true
    @Published var isPresentedSaveCompleteAlert = false
    @Published var displayTime: String
    var gpsManager = GPSManager()
    var getSensorModel = GetSenorModel.shared
    var sendFileWCSession = SendFileWCSession()
    
    init() {
        sendFileWCSession.wCSessionSetting()
        getSensorModel.checkMotionActive()
        self.displayTime = getSensorModel.displayTime
        
        self.getSensorModel.$displayTime.assign(to: &$displayTime)
    }
    
    func start() {
        getSensorModel.initializeSensorData()
        getSensorModel.startGetMotionData()
        gpsManager.startUpdata()
        isStopButtonDisabled = false
        isSaveButtonDisabled = true
    }
    
    func stop() {
        getSensorModel.stopGetMotionData()
        gpsManager.stopUpdate()
        isStopButtonDisabled = true
        isSaveButtonDisabled = false
    }
    
    func save() {
        isPresentedSaveCompleteAlert = sendFileWCSession.sendFile()
    }
    
    func allInitialize() {
        isSaveButtonDisabled = true
        isStopButtonDisabled = true
        isPresentedSaveCompleteAlert = false
        displayTime = "0.00"
        gpsManager = GPSManager()
        getSensorModel = GetSenorModel.shared
        sendFileWCSession = SendFileWCSession()
    }
}
