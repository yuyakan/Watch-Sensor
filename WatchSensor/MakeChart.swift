//
//  MakeChart.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/07/05.
//

import Foundation
import DGCharts

class MakeChart {
    var chartDataSet: LineChartDataSet!
    private let scrollHeight: CGFloat = UIScreen.main.bounds.height / 4
    private let width: CGFloat = UIScreen.main.bounds.width
    
    func setUpCharts(Charts: [LineChartView], scrollView: UIScrollView) {
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(Charts.count) ,height: scrollHeight)
        Charts.forEach { chart in
               scrollView.addSubview(chart)
        }
    }
    
    func makeGraphData (sensorInfo: String) -> (data: [[Double]], labels: [String]){
        var data: [[Double]] = []
        
        var csvLines = sensorInfo.components(separatedBy: .newlines)
        let labels = csvLines.removeFirst()
        let labelsSeparate = labels.components(separatedBy: ",")
        
        for _ in labelsSeparate {
            data.append([Double]())
        }
        
        for line in csvLines {
            let cells = line.components(separatedBy: ",")
            
            for i in 0..<cells.count {
                data[i].append(Double(cells[i].trimmingCharacters(in: .whitespaces))!)
            }
        }
        
        return (data, labelsSeparate)
    }
    
    
    func displayChart(data: [[Double]], LineChart: LineChartView, label: String) {
           
        var dataEntries = [ChartDataEntry]()

        for (time, data) in zip(data[0], data[1]) {
           let dataEntry = ChartDataEntry(x: time, y: data)
           dataEntries.append(dataEntry)
        }
        // グラフにデータを適用
        chartDataSet = LineChartDataSet(entries: dataEntries, label: label)
        
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.lineWidth = 2.0
        
        LineChart.data = LineChartData(dataSet: chartDataSet)
        LineChart.gridBackgroundColor = UIColor.white
        //グラフのView設定
        LineChart.drawGridBackgroundEnabled = true
        LineChart.xAxis.drawGridLinesEnabled = false
        LineChart.leftAxis.drawGridLinesEnabled = false
        LineChart.xAxis.labelPosition = .bottom
        LineChart.rightAxis.enabled = false
        LineChart.highlightPerTapEnabled = false
        LineChart.legend.enabled = true
        LineChart.pinchZoomEnabled = false
        LineChart.doubleTapToZoomEnabled = false
        LineChart.animate(xAxisDuration: 2)
        LineChart.dragEnabled = false
    }
    
}
