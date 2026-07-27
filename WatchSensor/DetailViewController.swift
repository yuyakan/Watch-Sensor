//
//  DetailViewController.swift
//  WatchSensor
//
//  （旧 UIKit の詳細画面を SwiftUI 化。ファイル名は互換のため維持）
//  Swift Charts でセンサーデータを描画し、CSV を Documents/ へエクスポートする。
//

import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: SessionRecord

    @StateObject private var adManager = InterstitialAdManager()
    @State private var showSavedAlert = false
    @State private var exportFailed = false

    private let makeChart = MakeChart()
    private let exportFile = ExportFile()

    private var chartGroups: [SensorChartGroup] {
        makeChart.makeChartGroups(sensorInfo: session.fileInfo.sensorInfo.count > 1
                                  ? session.fileInfo.sensorInfo[1] : "")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.spacing) {
                header

                if chartGroups.isEmpty {
                    noDataCard
                } else {
                    ForEach(chartGroups) { group in
                        SensorChartCard(group: group)
                    }
                }

                exportButton
                    .padding(.top, Metrics.spacingSmall)
            }
            .padding(Metrics.spacing)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle(session.directoryName)
        .navigationBarTitleDisplayMode(.inline)
        .brandDialog(
            isPresented: $showSavedAlert,
            imageName: "file",
            title: "Save completed",
            message: "saveFile"
        ) {
            // OK 後に、次回保存に備えてインタースティシャル広告を表示する。
            adManager.present()
        }
        .alert("Export failed", isPresented: $exportFailed) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            Label(session.directoryName, systemImage: "waveform.path.ecg")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Text("Motion & GPS recording")
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandCard()
    }

    private var noDataCard: some View {
        VStack(spacing: Metrics.spacingSmall) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(Brand.textSecondary)
            Text("No chartable data")
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .brandCard()
    }

    private var exportButton: some View {
        Button {
            export()
        } label: {
            Label("Export CSV", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(BrandButtonStyle())
    }

    private func export() {
        if exportFile.exportFiles(fileInfo: session.fileInfo) {
            showSavedAlert = true
        } else {
            exportFailed = true
        }
    }
}

/// センサーカテゴリ1つ分（X/Y/Z の3系列）を1つのグラフに重ねて表示するカード。
struct SensorChartCard: View {
    let group: SensorChartGroup

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            Text(group.title)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            Chart {
                ForEach(group.series) { series in
                    ForEach(series.points) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Axis", series.label))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartForegroundStyleScale(range: Brand.axisColors)
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 200)
        }
        .brandCard()
    }
}
