//
//  MakeChart.swift
//  WatchSensor
//
//  CSV 文字列を Swift Charts で描画できる形へ変換するパーサ。
//  旧実装（DGCharts + 強制アンラップ）を廃し、不正行・空行・欠損値に強い実装にした。
//

import Foundation

/// グラフ1本分の点列。
struct ChartSeries: Identifiable {
    let id = UUID()
    /// 系列名（"accelerationX" など）。
    let label: String
    /// (time, value) の点列。
    let points: [ChartPoint]
}

/// グラフ上の1点。
struct ChartPoint: Identifiable {
    let id = UUID()
    let time: Double
    let value: Double
}

/// グラフ画面用に、加速度・回転などのカテゴリごとにまとめた系列集合。
struct SensorChartGroup: Identifiable {
    let id = UUID()
    let title: String
    let series: [ChartSeries]
}

final class MakeChart {

    /// CSV をパースして (列ごとの数値配列, ラベル配列) を返す。
    ///
    /// 先頭行をラベル、以降を数値行として扱う。
    /// 数値化できないセルを含む行・列数が合わない行・空行は安全にスキップする。
    /// （従来は `Double(...)!` で末尾空行や不正値のたびにクラッシュしていた）
    func makeGraphData(sensorInfo: String) -> (data: [[Double]], labels: [String]) {
        var csvLines = sensorInfo.components(separatedBy: .newlines)
        guard !csvLines.isEmpty else { return ([], []) }

        let header = csvLines.removeFirst()
        let labels = header.components(separatedBy: ",")
        guard !labels.isEmpty else { return ([], []) }

        var data: [[Double]] = Array(repeating: [Double](), count: labels.count)

        for line in csvLines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }

            let cells = line.components(separatedBy: ",")
            // 列数が合わない行はスキップ。
            guard cells.count == labels.count else { continue }

            // 各セルを数値化。1つでも失敗したらこの行は丸ごとスキップする。
            let values = cells.map { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard values.allSatisfy({ $0 != nil }) else { continue }

            for (i, value) in values.enumerated() {
                data[i].append(value!)
            }
        }

        return (data, labels)
    }

    /// センサー CSV を、画面表示用のグループ（加速度 / 回転 / 重力 / 姿勢）に変換する。
    /// 各グループは X/Y/Z の3系列を持つ。列が足りない場合は存在する分だけ返す。
    func makeChartGroups(sensorInfo: String) -> [SensorChartGroup] {
        let (data, labels) = makeGraphData(sensorInfo: sensorInfo)
        guard data.count >= 2, let times = data.first, !times.isEmpty else { return [] }

        // 先頭列(index 0)が time。以降を3列ずつグループ化する。
        let groupTitles = [
            String(localized: "Acceleration"),
            String(localized: "Rotation Rate"),
            String(localized: "Gravity"),
            String(localized: "Attitude")
        ]

        var groups: [SensorChartGroup] = []
        var columnIndex = 1
        var titleIndex = 0

        while columnIndex < data.count {
            var series: [ChartSeries] = []
            let axisSuffix = ["X", "Y", "Z"]
            var axis = 0
            while axis < 3 && columnIndex < data.count {
                let column = data[columnIndex]
                let label = trimmedLabel(labels, at: columnIndex, fallbackSuffix: axisSuffix[axis])
                let points = zip(times, column).map { ChartPoint(time: $0.0, value: $0.1) }
                series.append(ChartSeries(label: label, points: points))
                columnIndex += 1
                axis += 1
            }
            let title = titleIndex < groupTitles.count ? groupTitles[titleIndex] : "Sensor \(titleIndex + 1)"
            groups.append(SensorChartGroup(title: title, series: series))
            titleIndex += 1
        }

        return groups
    }

    private func trimmedLabel(_ labels: [String], at index: Int, fallbackSuffix: String) -> String {
        guard index < labels.count else { return fallbackSuffix }
        let raw = labels[index].trimmingCharacters(in: .whitespaces)
        return raw.isEmpty ? fallbackSuffix : raw
    }
}
