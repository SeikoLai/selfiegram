//
//  SelfieListViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/1/26.
//

import UIKit
import CoreLocation

class SelfieListViewController: UITableViewController {
    
    // 儲存 Core Location 找出的最新地點
    var lastLocation: CLLocation?
    
    let locationManager = CLLocationManager()
    
    // 用來製作標籤“1 分鐘以前”
    let timeIntervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.maximumUnitCount = 1
        return formatter
    }()
    
    // 我們要顯示的圖片物件清單
    var selfies: [Selfie] = []
    
    var detailViewController: SelfieDetailViewController?
    
    @objc func createNewSelfie() {
        // 清掉上次的地點，這樣下張圖片才不會誤用已過期的地點資訊
        lastLocation = nil
        
        let shouldGetLocation = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        
        if shouldGetLocation {
            // 處理授權狀態
            switch locationManager.authorizationStatus {
                case .denied, .restricted:
                    // 可能沒有取得授權，或使用者根本無法使用地點服務
                    // 放棄動作
                    return
                case .notDetermined:
                    // 無法確認是否得到授權，所以要求授權
                    locationManager.requestWhenInUseAuthorization()
                default:
                    // 已經取得授權，不處理任何事情
                    break
            }
            // 將自己設為地點管理器的 delegate
            locationManager.delegate = self
            
            // 要求地點更新
            locationManager.requestLocation()
        }
        // 建立影像選擇棄
        let imagePicker = UIImagePickerController()
        
        // 如果相機可以使用，就用；否則使用相片庫
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            
            // 如果前置鏡頭可以使用，那就用前置鏡頭
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = .front
            }
        }
        else {
            imagePicker.sourceType = .photoLibrary
        }
        
        // 我們想要這個物件在使用者拍好照片以後收到通知，需要設定 delegate
        imagePicker.delegate = self
        
        // 顯示影像選擇器
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func showError(message: String) {
        // 建立一個 alert controller，初始化時傳入我們收到的訊息
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        // 為它加入一個動作－它除了顯示一個按鈕來退出它以外
        // 不做其他事情
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        // 顯示警示和訊息
        self.present(alert, animated: true, completion: nil)
    }
    
    // 當我們點擊在一列上時被呼叫
    // SelfieDetailViewController 會收到照片
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 如果是要過場到詳細頁，執行這邊邏輯
        if segue.identifier == "showDetail" {
            // 取得被點擊的cell位置資訊(IndexPath)
            if let indexPath = tableView.indexPathForSelectedRow {
                // 利用位置資訊從 selfies 中取出 selfie
                let selfie = selfies[indexPath.row]
                // 檢查目標的控制器是 SelfieDetailViewController
                if let controller = (segue.destination as? UINavigationController)?.topViewController as? SelfieDetailViewController {
                    controller.selfie = selfie
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 建立自拍的按鈕
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewSelfie))
        
        // 將自拍按鈕放到 navigation bar 的右邊
        navigationItem.rightBarButtonItem = addSelfieButton

        // 從 selfie store 載入自拍清單
        do {
            // 取得圖片清單，用日期排序（從新到舊）
            selfies = try SelfieStore.shared.listSelfies().sorted(by: {$0.created > $1.created} )
        }
        catch let error {
            showError(message: "Failed to load selfies: \(error.localizedDescription)")
        }
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as? UINavigationController)?.topViewController as? SelfieDetailViewController
        }
        
        // 為了要在收到最新座標後處理事情，將 CLLocationManager 的 delegate 設成自己
        self.locationManager.delegate = self
        // 設定座標精準度為 10 公尺
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 重新載入所有 table view 中的資料
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 從 table view 取得 cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // 取得自拍照並用來設定 cell
        let selfie = selfies[indexPath.row]
        
        // 取得自拍照建立時間
        let interval = timeIntervalFormatter.string(from: selfie.created, to: Date())
        
//        if #available(iOS 14.0, *) {
//            // iOS 14 改用 UIListContentConfiguration 設定 cell 樣式
//            var content = cell.defaultContentConfiguration()
//
//            // 設定 cell 的主標籤
//            content.text = selfie.title
//
//            // 設定多久以前拍的子標籤
//            if interval != nil {
//                content.secondaryText = "\(interval!) ago"
//            }
//
//            // 設定 cell 左側的圖示
//            content.image = selfie.image
//
//            // 設定 cell 配置檔
//            cell.contentConfiguration = content
//        }
//        else {
            // 設定 cell 的主標籤
            cell.textLabel?.text = selfie.title
            
            // 設定多久以前拍的子標籤
            cell.detailTextLabel?.text = interval != nil ? "\(interval!) ago" : nil
            
            // 設定 cell 左側的圖示
            cell.imageView?.image = selfie.image
//        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        // 如果發生編輯事件是刪除，執行刪除的邏輯
//        if editingStyle == .delete {
//
//            // 從 selfies 取得要刪除的物件
//            let selfieToRemove = selfies[indexPath.row]
//
//            // 試著刪除自拍照
//            do {
//                try SelfieStore.shared.delete(selfie: selfieToRemove)
//
//                // 從 selfies 刪除該張自拍照
//                selfies.remove(at: indexPath.row)
//
//                // 從 table view 中刪除該 cell
//                tableView.deleteRows(at: [indexPath], with: .fade)
//            }
//            catch {
//                let title = selfieToRemove.title
//                showError(message: "Failed to delete \(title)")
//            }
//        }
//    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 建立分享的動作
        let shareAction = UIContextualAction(style: .normal,
                                             title: "Share",
                                             handler: { (action, sourceView, completionHandler) in
            // 要分享的自拍照，如果找不到就不分享並且 log 錯誤
            guard let image = self.selfies[indexPath.row].image else {
                self.showError(message: "Unable to share selfie without image")
                return
            }
            
            // 建立分享控制器，分享自拍照
            let activity = UIActivityViewController(activityItems: [image],
                                                    applicationActivities: nil)
            self.present(activity, animated: true, completion: nil)
            
            completionHandler(true)
        })
        // 指定分享按鈕的顏色
        shareAction.backgroundColor = self.navigationController?.navigationBar.tintColor
        
        // 建立刪除的動作
        let deleteAction = UIContextualAction(style: .destructive,
                                              title: "Delete",
                                              handler: { (action, sourceView, completionHandler) in
            // 從 selfies 取得要刪除的物件
            let selfieToRemove = self.selfies[indexPath.row]
            
            // 試著刪除自拍照
            do {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                
                // 從 selfies 刪除該張自拍照
                self.selfies.remove(at: indexPath.row)
                
                // 從 table view 中刪除該 cell
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            catch {
                let title = selfieToRemove.title
                self.showError(message: "Failed to delete \(title)")
            }
            completionHandler(true)
        })
        
        // 將分享跟刪除動作加入手勢配置檔
        let configuration = UISwipeActionsConfiguration(actions: [shareAction, deleteAction])
        // 關閉滑動到底觸發第一個按鈕
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }
}

// MARK: UIImagePickerControllerDelegate
extension SelfieListViewController: UIImagePickerControllerDelegate {
    // 當使用者取消選取圖片時呼叫
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 當使用者完成一張圖片時呼叫
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            showError(message: "Couldn't get a picture from the image picker!")
            return
        }
        
        self.newSelfieTaken(image: image)
        
        // 關閉 picker
        self.dismiss(animated: true, completion: nil)
    }
    
    // 使用者選完一張照片後呼叫
    func newSelfieTaken(image: UIImage) {
        // 建立一張自拍照
        let newSelfie = Selfie(title: "New Selfie")
        
        // 放入圖片
        newSelfie.image = image
        
        // 檢查地點是否存在
        if let location = self.lastLocation {
            // 將地點轉為 Coordinate 型態後存在自拍照
            newSelfie.position = Selfie.Coordinate(location: location)
        }
        
        // 試著儲存照片
        do {
            try SelfieStore.shared.save(selfie: newSelfie)
        }
        catch let error {
            showError(message: "Can't save photo: \(error.localizedDescription)")
            return
        }
        
        // 將自拍照插入 view controller 清單中
        selfies.insert(newSelfie, at: 0)
        
        // 更新 table view 以顯示新的自拍照
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
}

// MARK: UINavigationControllerDelegate
extension SelfieListViewController: UINavigationControllerDelegate {
}

// MARK: CLLocationManagerDelegate
extension SelfieListViewController: CLLocationManagerDelegate {
    
    // 取得地點後被呼叫
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         self.lastLocation = locations.last
    }
    
    // 發生錯誤時被呼叫
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showError(message: error.localizedDescription)
    }
}
