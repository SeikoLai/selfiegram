//
//  CaptureViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/2/10.
//

import UIKit
import AVKit

class PreviewView: UIView {
    // 顯示預覽影像的圖層
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setSession(_ session: AVCaptureSession) {
        // 避免重複疊加圖層
        guard self.previewLayer == nil else {
            print("Warning: \(self.description) attempted to set its preview layer more than once. This is not allowed.")
            return
        }
        
        // 建立預覽的圖層，並從影像擷取處取得播放內容
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // 同時保持原畫面比例
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // 將預覽圖層加到我們的圖層中
        self.layer.addSublayer(previewLayer)
        
        // 將參照存在圖層中
        self.previewLayer = previewLayer
        
        // 確保子圖層有被繪製
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        // 設定預覽影像圖層的尺寸
        previewLayer?.frame = self.bounds
    }
    
    // 依照參數的方向，設定影片圖層的方向
    func setCameraOrientation(_ orientation: AVCaptureVideoOrientation) {
        previewLayer?.connection?.videoOrientation = orientation
    }
}

class CaptureViewController: UIViewController {
    typealias CompletionHandler = (UIImage?) -> Void
    var completion: CompletionHandler?
    
    // 建立工作階段（session），相機畫面即時串流
    let captureSession = AVCaptureSession()
    // 照片輸出介面
    let photoOutput = AVCapturePhotoOutput()
    
    // 方向計算屬性
    var currentViewOrientation: AVCaptureVideoOrientation {
        // 這屬性用來匹配裝置與影片的方向
        // 因為裝置跟影片的方向是各自獨立的
        let orientationMap: [UIDeviceOrientation: AVCaptureVideoOrientation]
        
        orientationMap = [
            .portrait: .portrait,
            .landscapeLeft: .landscapeRight,
            .landscapeRight: .landscapeLeft,
            .portraitUpsideDown: .portraitUpsideDown
        ]
        
        // 取得現在裝置方向
        let currentOrientation = UIDevice.current.orientation
        
        // 指定影片方向，預設是 portrait
        let videoOrientation = orientationMap[currentOrientation, default: .portrait]
        
        return videoOrientation
    }
    
    @IBOutlet weak var cameraPreview: PreviewView!
    
    @IBAction func close(_ sender: Any) {
        self.completion?(nil)
    }
    
    @IBAction func takeSelfie(_ sender: Any) {
        // 取得照片輸出的連結
        guard let videoConnection = photoOutput.connection(with: AVMediaType.video) else {
            print("failed to get camera connection")
            return
        }
        
        // 設定方向，這樣影片方向才會正確
        videoConnection.videoOrientation = currentViewOrientation
        
        // 指出我們想要擷取的是 JPEG 格式
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        // 開始抓取一張照片；完成時它會呼叫
        // photoOutput(_, didFinishProcessingPhoto:, error:)
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // 裝置方向改變時呼叫
    override func viewWillLayoutSubviews() {
        // 更新影片預覽的方向
        self.cameraPreview?.setCameraOrientation(currentViewOrientation)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 設定擷取裝置配置：廣角鏡頭（builtInWideAngleCamera）、能擷取影片、使用前置鏡頭
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.front)
        
        // 使用擷取裝置配置檔找尋可用裝置，如果找不到就放棄執行
        guard let captureDevice = discovery.devices.first else {
            print("No capture devices available.")
            self.completion?(nil)
            return
        }
        
        // 將取得的裝置加入工作階段中
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        }
        catch let error {
            print("Failed to add camera to capture session: \(error.localizedDescription)")
            self.completion?(nil)
        }
        
        // 將相機設定為適合拍照的高解析度擷取
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        // 啟動擷取工作階段
        captureSession.startRunning()
        
        // 將照片 output 加入工作階段
        // 這樣就可以在想要的時候取得照片
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // 設定相機畫面的擷取工作階段
        self.cameraPreview.setSession(captureSession)
        
        super.viewDidLoad()
    }
}

// MARK: AVCapturePhotoCaptureDelegate
extension CaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Failed to get the photo: \(error)")
            return
        }
        
        // 從擷取裝置取得照片數據，將照片數據轉為照片，如果失敗就結束
        guard let jpegData = photo.fileDataRepresentation(),
              let image = UIImage(data: jpegData) else {
                  print("Failed to get image from encoded data")
                  return
              }
        
        self.completion?(image)
    }
}
