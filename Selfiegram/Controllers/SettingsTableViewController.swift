//
//  SettingsTableViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/2/9.
//

import UIKit

enum SettingsKey: String {
    case saveLocation
}

class SettingsTableViewController: UITableViewController {

    // 儲存地點開關
    @IBOutlet weak var locationSwitch: UISwitch!
    
    @IBAction func locationSwitchToggled(_ sender: Any) {
        // 更新 UserDefaults 設定
        UserDefaults.standard.set(locationSwitch.isOn,
                                  forKey: SettingsKey.saveLocation.rawValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 確認儲存地點開關有被正確地設定
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
    }
}
