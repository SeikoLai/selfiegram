//
//  SelfieDetailViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/1/26.
//

import UIKit
import MapKit

class SelfieDetailViewController: UIViewController {

    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var deteCreatedLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func expandMap(_ sender: Any) {
        // 如果有座標資訊才配置地圖並且放置大頭針
        if let coordinate = self.selfie?.position?.location {
            // 設定地圖的配置
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate.coordinate),
                MKLaunchOptionsMapTypeKey: NSNumber(value: MKMapType.mutedStandard.rawValue)
            ]
            
            // 建立大頭針物件
            let placemark = MKPlacemark(
                coordinate: coordinate.coordinate,
                addressDictionary: nil)
            
            // 建立大頭針所需內容物件
            let item = MKMapItem(placemark: placemark)
            item.name = selfie?.title
            item.openInMaps(launchOptions: options)
        }
    }
    
    
    var selfie: Selfie? {
        didSet {
            // 更新 view
            configureView()
        }
    }
    
    // 日期格式用來格式化照片要用的時間和日期
    // 它在一個 closure 中建立，如此一來，當我們要使用時，就會是我們要的格式
    let dateFormatter = { () -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    func configureView() {
        guard let selfie = selfie else {
            return
        }
        
        // 確認拿到的是我們想要的控制項
        guard let selfieNameField = selfieNameField,
              let selfieImageView = selfieImageView,
              let deteCreatedLabel = deteCreatedLabel else
        {
            return
        }
        
        selfieNameField.text = selfie.title
        selfieImageView.image = selfie.image
        deteCreatedLabel.text = dateFormatter.string(from: selfie.created)
        
        if let position = selfie.position {
            self.mapView.setCenter(position.location.coordinate, animated: false)
            mapView.isHidden = false
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        // 關閉鍵盤
        self.selfieNameField.resignFirstResponder()
        
        // 確定有可用的自拍照
        guard let selfie = selfie else {
            return
        }
        
        // 確定文字欄位有文字
        guard let text = selfieNameField?.text else {
            return
        }
        
        // 更新自拍照並且儲存
        selfie.title = text
        try? SelfieStore.shared.save(selfie: selfie)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 更新 view
        configureView()
    }
}
