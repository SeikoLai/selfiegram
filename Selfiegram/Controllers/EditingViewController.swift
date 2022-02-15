//
//  EditingViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/2/14.
//

import UIKit
import Vision

class OverlaySelectionView: UIImageView {
    
    // 用來取得疊加圖所需圖片
    let overlay: Overlay
    
    // 處理使用者點擊圖片後的動作
    typealias TapHandler = () -> Void
    let tapHandler: TapHandler
    
    init(overlay: Overlay, tapHandler: @escaping TapHandler) {
        
        self.overlay = overlay
        self.tapHandler = tapHandler
        
        super.init(image: overlay.previewIcon)
        
        // UIImageViiew 的 isUserInteractionEnabled 預設為 false
        // 並需要將此屬屬性指定成 true，才能回應點擊
        self.isUserInteractionEnabled = true
        
        // 當點擊發生時，我們將會呼叫的方法
        let tappedMethod = #selector(OverlaySelectionView.tapped(tap:))
        
        // 建立並加入一個點擊手勢辨識器，並給定想要執行的方法
        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: tappedMethod)
        
        self.addGestureRecognizer(tapRecognizer)
    }
    
    // 處理點擊的程式碼
    @objc func tapped(tap: UITapGestureRecognizer) {
        self.tapHandler()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EditingViewController: UIViewController {
    // 左眉毛與右眉毛
    enum EyebrowType { case left, right}
    
    // 眉毛由他的形態和位置組成
    typealias EyebrowPosition = (type: EyebrowType, position: CGPoint)
    
    // DetectionResult 代表辨識成功或失敗
    // 它用 associated values 裝載額外資訊
    enum DetectionResult {
        case error(Error)
        case success([EyebrowPosition])
    }
    
    // 錯誤型態只有一種：找不到任何眉毛
    enum DetectionError: Error { case noResults }
    
    // 偵測的完成處理是由一個 closure 負責，在這個 closure 中
    // 會查看偵測結果
    typealias DetectionCompletion = (DetectionResult) -> Void

    // 從 CaptureViewcontroller 處得到的圖片
    var image: UIImage?
    
    // 畫完眉毛以後的圖片
    var renderedImage: UIImage?
    
    // 偵測出的眉毛位置 list
    var eyebrows: [EyebrowPosition] = []
    
    var overlays: [Overlay] = []
    
    var currentOverlay: Overlay? = nil {
        didSet {
            guard currentOverlay != nil else { return }
            redrawImage()
        }
    }
    
    var completion: CaptureViewController.CompletionHandler?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var optionsStackView: UIStackView!
    
    /// UIImage 是 immutable 的，技術上來說完全不能改變有的圖片。
    /// 取而代之，我們將會建立一個新的圖片，這個新的圖片會合併原始圖片，
    /// 以及在原始圖片上疊加眉毛圖，完成的結果會儲存在本地端
    func redrawImage() {
      // 確認有要畫的疊加圖層，也有可在上畫洞悉的原始圖片
        guard let overlay = self.currentOverlay,
              let image = self.image else {
                  return
              }
        
        // 1. UIGraphicsBeginImageContext 是一個方便函示，
        // 簡化 UIGraphicsBeginImageContextWithOptions
        // UIGraphicsBeginImageContext 預設縮放比例為 1.0
        // 由於我們是既有的圖片當作畫布，所以比例不會有問題
        // 但是如果從頭開始做自己的圖片，縮放比例 1.0 會造成
        // 在高縮放比例的裝置上的影像顯示失真——例如 iOS 裝置。
        // 2. image context 其實就是呼叫 draw 時，它進行繪圖的記憶體
        // 開始繪圖，在畫完之後要確認明確地停止繪圖
        UIGraphicsBeginImageContext(image.size)

        defer {
            // 關閉圖片失敗的話，可能導致很多奇怪的事情發生。
            // 由於 iOS 有事沒有就會畫點陣圖，所以不收拾你的 context
            // 的話是很危險的一件事！
            UIGraphicsEndImageContext()
        }
        
        // 先把原始圖畫上去
        image.draw(at: CGPoint.zero)
        
        // 分別畫上左右眉毛
        for eyebrow in self.eyebrows {
            // 依眉毛的位置，選擇適當的圖片
            let eyebrowImage: UIImage
            
            switch eyebrow.type {
                case .left:
                    eyebrowImage = overlay.leftImage
                case .right:
                    eyebrowImage = overlay.rightImage
            }
            
            // 由於我們收的的座標是鏡向上下倒過來的（0,0 不是在左上方，而是在右下方）
            // 所以要把座標翻過來
            var position = CGPoint(x: image.size.width - eyebrow.position.x,
                                   y: image.size.height - eyebrow.position.y)
            
            // 以原始圖的左上角為準，畫圖
            // 由於我們想要圖片是置中對齊位置點
            // 所以將寬度和高度調整50%
            position.x -= eyebrowImage.size.width / 2.0
            position.y -= eyebrowImage.size.height / 2.0
            
            // 繪製眉毛
            eyebrowImage.draw(at: position)
        }
        
        // 畫完眉毛，取得圖片並儲存
        self.renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 也將圖片顯示在 image view 中
        self.imageView.image = self.renderedImage
    }
    
    @objc func done() {
        let imageToReturn = self.renderedImage ?? self.image
        
        self.completion?(imageToReturn)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 如果找不到圖片就離開
        guard let image = image else {
            self.completion?(nil)
            return
        }
        self.imageView.image = image
        
        // 準備好疊加圖資訊
        overlays = OverlayManager.shared.availableOverlays()
        
        for overlay in overlays {
            let overlayView = OverlaySelectionView(overlay: overlay) {
                self.currentOverlay = overlay
            }
            
            overlays.append(overlay)
            
            optionsStackView.addArrangedSubview(overlayView)
        }
        // 加入一個完成按鈕
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .done,
                                              target: self,
                                              action: #selector(done))
        navigationItem.rightBarButtonItem = addSelfieButton
        
        // 呼叫偵測眉毛的程式碼，然後將眉毛儲存到屬性中
        self.detectEyebrows(image: image, completion: { (eyebrows) in
            self.eyebrows = eyebrows
        })
    }
    
    /// 負責取得眉毛的位置
    /// - Parameters:
    ///   - request: 從中取得臉部偵測的資訊
    ///   - imageSize: 圖片尺寸
    ///   - completion: 完成函式
    private func locateEyebrowsHandler(_ request: VNRequest,
                                       imageSize: CGSize,
                                       completion: DetectionCompletion) {
        // 如果找不到任何臉部的話，就沒有眉毛可以偵測
        // 判斷為錯誤並且離開
        guard let firstFace = request.results?.first as? VNFaceObservation else {
            completion(.error(DetectionError.noResults))
            return
        }
        
        // 特徵區域包含很多點，這些點用來描述特徵的輪廓
        // 我們只想要知道把眉毛貼在圖片的位置
        // 所以不需要用上全部的輪廓，只要知道眉毛就可以
        // 可以將所有的點平均，已取得眉毛位置
        // 有內建的函式可以使用
        func averagePosition(for landmark: VNFaceLandmarkRegion2D) -> CGPoint {
            
            // 取得圖像中所有的點
            let points = landmark.pointsInImage(imageSize: imageSize)
            
            // 將所有的點加總
            var averagePoint = points.reduce(CGPoint.zero, { return CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) })
            
            // 將加總除以點個數，產生平均點
            averagePoint.x /= CGFloat(points.count)
            averagePoint.y /= CGFloat(points.count)
            
            return averagePoint
        }
        
        // 開始建立眉毛清單
        var results: [EyebrowPosition] = []
        
        // 試著去取得每道眉毛，計算它的位置，並儲存在 results 中
        if let leftEyebrow = firstFace.landmarks?.leftEyebrow {
            let position = averagePosition(for: leftEyebrow)
            results.append((type: .left, position: position))
        }
        
        if let rightEyebrow = firstFace.landmarks?.rightEyebrow {
            let position = averagePosition(for: rightEyebrow)
            results.append((type: .right, position: position))
        }
        
        // 將眉毛清單傳出去，並表示作業成功
        completion(.success(results))
    }
    
    /// 偵測圖片中的特徵
    /// - Parameters:
    ///   - image: 要偵測特徵的圖片
    ///   - completion: 完成函式
    func detectFaceLandmarks(image: UIImage, completion: @escaping DetectionCompletion) {
        // 準備一個 request，用來偵測臉部特徵
        // 臉部特徵指的是象鼻子、眼睛、眉毛⋯⋯等
        let request = VNDetectFaceLandmarksRequest { [unowned self] request, error in
            
            if let error = error {
                completion(.error(error))
                return
            }
            
            // 這個 request 現在已含有臉部特徵資料了，將它傳給我們的
            // 處理函式，處理函式會從這些資料中取出想要的特定資訊
            self.locateEyebrowsHandler(request, imageSize: image.size, completion: completion)
        }
        
        // 為圖片建立一個處理器，處理 request
        let handler = VNImageRequestHandler(cgImage: image.cgImage!,
                                            orientation: .leftMirrored,
                                            options: [:])
        
        // 試著在處理器上執行 request，並 catch 所有錯誤
        do {
            try handler.perform([request])
        }
        catch {
            completion(.error(error))
        }
    }
    
    /// 呼叫 -detectFaceLandmarks(image: completion:)，將結果以比較好的介面呈現
    /// - Parameters:
    ///   - image: 偵測特徵的圖片
    ///   - completion: 完成函式
    func detectEyebrows(image: UIImage, completion: @escaping ([EyebrowPosition]) -> Void) {
        detectFaceLandmarks(image: image) { (result) in
            switch result {
                case .error(let error):
                    // 分析特徵失敗，直接回傳原始圖片
                    print("Error detecting eyebrows: \(error)")
                    completion([])
                case .success(let results):
                    completion(results)
            }
        }
    }
}
