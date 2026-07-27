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
    // @StateObject にすることで、View が再描画されても ViewModel が保持され、
    // 計測中の状態が失われない（@ObservedObject + 初期化式は再生成されるアンチパターン）。
    @StateObject var homeViewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack() {
                Text(homeViewModel.displayTime)
                    .font(.largeTitle)
                    .padding(.vertical, 10)
                Button(action: {homeViewModel.start()}, label: {
                    Text("Start")
                })
                .disabled(homeViewModel.isStartButtonDisabled)
                .opacity(homeViewModel.isStartButtonDisabled ? 0.5 : 1)
                Button(action: {homeViewModel.stop()}, label: {
                    Text("Stop")
                })
                .disabled(homeViewModel.isStopButtonDisabled)
                .opacity(homeViewModel.isStopButtonDisabled ? 0.5 : 1)
                Button(action: {homeViewModel.save()}, label: {
                    Text(homeViewModel.isSending ? "Sending..." : "Save")
                })
                .disabled(homeViewModel.isSaveButtonDisabled || homeViewModel.isSending)
                .opacity((homeViewModel.isSaveButtonDisabled || homeViewModel.isSending) ? 0.5 : 1)
            }
            .alert("Save complete", isPresented: $homeViewModel.isPresentedSaveCompleteAlert) {
                Button("OK") {homeViewModel.allInitialize()}
            }
            .alert("Save failed", isPresented: $homeViewModel.isPresentedSaveErrorAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

class HomeViewModel: ObservableObject {
    /// 計測中は Start を無効化する（再 Start による計測データ消去・motion二重起動を防ぐ）。
    @Published var isStartButtonDisabled = false
    @Published var isStopButtonDisabled = true
    @Published var isSaveButtonDisabled = true
    @Published var isPresentedSaveCompleteAlert = false
    @Published var isPresentedSaveErrorAlert = false
    /// 送信中はボタンを無効化して二重送信を防ぐ。
    @Published var isSending = false
    @Published var displayTime: String
    // GPSManager / SendFileWCSession は使い回す（作り直すと WCSession デリゲートが
    // 重複登録され、GPS の許可要求も毎回走ってしまうため）。
    let gpsManager = GPSManager()
    let getSensorModel = GetSenorModel.shared
    let sendFileWCSession = SendFileWCSession()

    init() {
        sendFileWCSession.wCSessionSetting()
        getSensorModel.checkMotionActive()
        self.displayTime = getSensorModel.displayTime

        self.getSensorModel.$displayTime.assign(to: &$displayTime)
    }

    func start() {
        // 計測中の再 Start はデータ消去・motion二重起動につながるため弾く。
        guard !isStartButtonDisabled else { return }

        getSensorModel.initializeSensorData()
        getSensorModel.startGetMotionData()
        gpsManager.startUpdata()

        // 計測中の状態に統一する（前回の保存関連状態も念のため解除）。
        isStartButtonDisabled = true
        isStopButtonDisabled = false
        isSaveButtonDisabled = true
        isSending = false
    }

    func stop() {
        guard !isStopButtonDisabled else { return }

        getSensorModel.stopGetMotionData()
        gpsManager.stopUpdate()

        isStartButtonDisabled = false
        isStopButtonDisabled = true
        isSaveButtonDisabled = false
    }

    func save() {
        guard !isSending else { return }
        isSending = true
        isSaveButtonDisabled = true
        // transferFile は非同期。実際の転送完了（またはエラー）を待ってから結果を反映する。
        sendFileWCSession.sendFile { [weak self] result in
            guard let self else { return }
            self.isSending = false
            switch result {
            case .success:
                self.isPresentedSaveCompleteAlert = true
            case .failure(let error):
                print("send file failed: \(error)")
                // 失敗時はもう一度保存できるよう Save を再度有効化する。
                self.isSaveButtonDisabled = false
                self.isPresentedSaveErrorAlert = true
            }
        }
    }

    /// 保存完了アラートの OK 後に、次の計測に備えて状態を初期化する。
    func allInitialize() {
        isStartButtonDisabled = false
        isSaveButtonDisabled = true
        isStopButtonDisabled = true
        isPresentedSaveCompleteAlert = false
        isSending = false
        displayTime = "0.00"
        getSensorModel.initializeSensorData()
    }
}
