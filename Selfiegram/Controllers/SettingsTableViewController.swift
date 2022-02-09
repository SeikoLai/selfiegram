//
//  SettingsTableViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/2/9.
//

import UIKit
import UserNotifications

enum SettingsKey: String {
    case saveLocation
}

class SettingsTableViewController: UITableViewController {
    private let notificationId = "SelfiegramReminder"
    
    // 儲存地點開關
    @IBOutlet weak var locationSwitch: UISwitch!
    // 推播通知開關
    @IBOutlet weak var remindSwitch: UISwitch!
    
    @IBAction func locationSwitchToggled(_ sender: Any) {
        // 更新 UserDefaults 設定
        UserDefaults.standard.set(locationSwitch.isOn,
                                  forKey: SettingsKey.saveLocation.rawValue)
    }
    @IBAction func remindSwitchToggled(_ sender: Any) {
        // 取得推播中心
        let current = UNUserNotificationCenter.current()
        
        switch remindSwitch.isOn {
            case true:
                // 定義要送的通知類型
                // 這邊使用簡單的提示通知
                let notificationOptions: UNAuthorizationOptions = [.alert]
                
                // 選項是開啟的，要求要送出通知的授權
                current.requestAuthorization(
                    options: notificationOptions,
                    completionHandler: { (granted, error) in
                        if granted {
                            // 取得授權，將通知加到佇列中
                            self.addNotificationRequest()
                        }
                        
                        // 呼叫 updateReminderSwitch
                        // 因為可能沒有獲得授權
                        self.updateReminderSwitch()
                    })
            case false:
                // 選項是關閉的
                // 清空待執行的通知要求
                current.removeAllPendingNotificationRequests()
        }
    }
    
    func addNotificationRequest() {
        // 取得通知中心
        let current = UNUserNotificationCenter.current()
        
        // 移除所有既存的通知
        // 避免使用者多次切換開關後，在下一次觸發時間收到很多通知
        current.removeAllPendingNotificationRequests()
        
        // 準備通知內容
        let content = UNMutableNotificationContent()
        content.title = "Take a selfie!"
        
        // 建立日期代表“早上10點”的元件（不指定哪一天）
        var components = DateComponents()
        components.setValue(10, for: Calendar.Component.hour)
        
#if DEBUG
        // 測試時的觸發時間較短
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10,
                                                        repeats: false)
#else
        // 每天在這個時間就會觸發
        let trigger = UNCalendarNotificationTrigger(dateMatching: components,
                                                    repeats: true)
#endif
        // 建立要求
        let request = UNNotificationRequest(identifier: self.notificationId,
                                            content: content,
                                            trigger: trigger)
        
        // 將要求加到推播中心
        current.add(request, withCompletionHandler: { (error) in
            // 通知要求被加入到推播中心時呼叫
            self.updateReminderSwitch()
        })
    }
    
    func updateReminderSwitch() {
        // 取得推播授權的狀態
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    // 臨時的(provisional)授權狀態
                    // 短暫的(ephemeral)授權狀態
                    // 已經取得授權(authorized)
                    
                    UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                        
                        // 如果要求串列中至少有 1 個要求的話
                        // 表示現在在啟動狀態
                        if requests.count > 0 {
                            let active = requests
                                .filter({ $0.identifier == self.notificationId})
                                .count > 0
                            
                            // 如果發現我們的通知在串列中
                            // 就將 switch 設定在開的位置
                            self.updateReminderUI(enabled: true, active: active)
                        }
                    })
                    
                case .denied:
                    // 如果使用者拒絕授權的話，設定 switch 到關的位置
                    // 並且禁止它的功能
                    self.updateReminderUI(enabled: false, active: false)
                    
                case .notDetermined:
                    // 若還未向使用者要過授權的話
                    // 打開 switch 的功能，但預設放在關的位置
                    self.updateReminderUI(enabled: true, active: false)
                    
                default:
                    // 未知的狀態
                    // 打開 switch 的功能，但預設放在關的位置
                    self.updateReminderUI(enabled: true, active: false)
                    break
            }
        })
    }
    
    func updateReminderUI(enabled: Bool, active: Bool) {
        OperationQueue.main.addOperation {
            self.remindSwitch.isEnabled = enabled
            self.remindSwitch.isOn = active
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 確認儲存地點開關有被正確地設定
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        
        updateReminderSwitch()
    }
}
