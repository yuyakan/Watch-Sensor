//
//  DetailViewController.swift
//  WatchSensor
//
//  Created by 上別縄祐也 on 2022/06/27.
//


import UIKit
import DGCharts
import GoogleMobileAds

class DetailViewController: UIViewController, UIScrollViewDelegate, FullScreenContentDelegate {
    
    private var makeChart = MakeChart()
    private var exportFile = ExportFile()
    
    var fileInfo: FileInfo = FileInfo(sensorInfo: [], gpsInfo: [], directoryInfo: "")
    
    private let scrollHeight: CGFloat = UIScreen.main.bounds.height / 4
    private var scrollWidth: CGFloat = 0.0
    private let width: CGFloat = UIScreen.main.bounds.width
    
    let interstitialADTestUnitID = "ca-app-pub-3940256099942544/4411468910"
    private var interstitial: InterstitialAd?

    // 広告取得失敗時の再試行（指数バックオフ）
    private var interstitialRetryCount = 0
    private let interstitialMaxRetryCount = 5

    override func viewDidLoad() {
        super.viewDidLoad()

        loadInterstitial()

        scrollWidth = firstScrollView.frame.size.width
        ExportButtonOutlet.layer.cornerRadius = 10
        ExportButtonOutlet.layer.shadowOpacity = 0.7
        ExportButtonOutlet.layer.shadowRadius = 3
        ExportButtonOutlet.layer.shadowColor = UIColor.black.cgColor
        ExportButtonOutlet.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        
        firstPageControl.numberOfPages = 3
        secondPageControl.numberOfPages = 3
        
        let accelCharts = [LineChartView(frame: CGRect(x: 0, y: 20, width: width * 0.98, height: scrollHeight * 0.9)),
                           LineChartView(frame: CGRect(x: scrollWidth * 1 + 2, y: 20, width: width * 0.98, height: scrollHeight * 0.9)),
                           LineChartView(frame: CGRect(x: scrollWidth * 2 + 2, y: 20, width: width * 0.98, height: scrollHeight * 0.9))]
        
        let rotationCharts = [LineChartView(frame: CGRect(x: 0, y: 20, width: width * 0.98, height: scrollHeight * 0.9)),
                              LineChartView(frame: CGRect(x: scrollWidth * 1 + 2, y: 20, width: width * 0.98, height: scrollHeight * 0.9)),
                              LineChartView(frame: CGRect(x: scrollWidth * 2 + 2, y: 20, width: width * 0.98, height: scrollHeight * 0.9))]
        
        let charts = accelCharts + rotationCharts
        
        let graphData = makeChart.makeGraphData(sensorInfo: fileInfo.sensorInfo[1])
        
        for i in 0...5 {
            makeChart.displayChart(data: [graphData.data[0], graphData.data[i + 1]], LineChart: charts[i], label:
                                    graphData.labels[i + 1])
        }
        
        makeChart.setUpCharts(Charts: accelCharts, scrollView: firstScrollView)
        makeChart.setUpCharts(Charts: rotationCharts, scrollView: secondScrollView)
    }
    
    @IBOutlet weak var ExportButtonOutlet: UIButton!
    
    @IBOutlet weak var firstScrollView: UIScrollView! {
        didSet {
            firstScrollView.delegate = self
            firstScrollView.isPagingEnabled = true
            firstScrollView.showsHorizontalScrollIndicator = false
        }
    }
    
    @IBOutlet weak var secondScrollView: UIScrollView! {
        didSet {
            secondScrollView.delegate = self
            secondScrollView.isPagingEnabled = true
            secondScrollView.showsHorizontalScrollIndicator = false
        }
    }
    
    
    @IBOutlet weak var firstPageControl: UIPageControl! {
        didSet {
            firstPageControl.isUserInteractionEnabled = false
        }
    }
    
    @IBOutlet weak var secondPageControl: UIPageControl! {
        didSet {
            secondPageControl.isUserInteractionEnabled = false
        }
    }
    
    
    @IBAction func ExportButton(_ sender: Any) {
        if exportFile.exportFiles(fileInfo: fileInfo) {
            let alert = UIAlertController(title: String(localized: "Save completed"), message: String(localized: "saveFile"), preferredStyle: .alert)
            let imageView = UIImageView(frame: CGRect(x: 10, y: 105, width: 250, height: 140))
            let height = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 320)
            alert.view.addConstraint(height)
            imageView.image = UIImage(named: "file")
            alert.view.addSubview(imageView)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:  { [weak self] _ in
                guard let self else { return }
                if let interstitial = self.interstitial {
                    self.interstitial = nil
                    interstitial.present(from: self)
                } else {
                    // 広告がまだ読み込めていない場合は次回のために取得しておく
                    self.loadInterstitial()
                }
            }))
            present(alert, animated: true)
        }
    }

    private func loadInterstitial() {
        InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: Request(),
              completionHandler: { [weak self] ad, error in
                guard let self else { return }
                if let error = error {
                  print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                  self.retryLoadInterstitial()
                  return
                }
                self.interstitialRetryCount = 0
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                print("sucess ad load")
              }
        )
    }

    // 取得失敗時、指数バックオフ（2, 4, 8, 16, 32秒）で最大5回まで再取得する
    private func retryLoadInterstitial() {
        guard interstitialRetryCount < interstitialMaxRetryCount else {
            print("Interstitial ad load failed after \(interstitialMaxRetryCount) retries. Giving up.")
            return
        }
        interstitialRetryCount += 1
        let delay = pow(2.0, Double(interstitialRetryCount))
        print("Retrying interstitial ad load (\(interstitialRetryCount)/\(interstitialMaxRetryCount)) in \(delay)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.loadInterstitial()
        }
    }

    // 広告が閉じられたら、次の保存時に表示できるよう再取得する
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialRetryCount = 0
        loadInterstitial()
    }

    // 表示に失敗した場合も次回に備えて再取得する
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad with error: \(error.localizedDescription)")
        interstitialRetryCount = 0
        loadInterstitial()
    }


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == firstScrollView {
            firstPageControl.currentPage = Int(scrollView.contentOffset.x / scrollWidth)
        } else if scrollView == secondScrollView {
            secondPageControl.currentPage = Int(scrollView.contentOffset.x / scrollWidth)
        }
    }
    
}
