//
//  Theme.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/2/9.
//

import Foundation
import UIKit

struct Theme {
 
    static func apply() {
        // 設定 header 字型，如果失敗則結束
        guard let headerFont = UIFont(familyName: "Lobster",
                                      size: UIFont.systemFontSize * 2) else {
            NSLog("Failed to load header font")
            return
        }
        
        // 設定 primary 字型，如果失敗則結束
        guard let primaryFont = UIFont(familyName: "Quicksand") else {
            NSLog("Failed to load application font")
            return
        }
        
        // 建立我們要的顏色
        let tintColor = UIColor(red: 0.56, green: 0.35, blue: 0.97, alpha: 1)
        
        if #available(iOS 13.0, *) {
            let navAppearance = UINavigationBarAppearance()
            // 設定 navigation bar 標題字體
            navAppearance.titleTextAttributes = [.font: headerFont]
            
            // 設定 navigation bar 按鈕外貌
            let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
            buttonAppearance.normal.titleTextAttributes = [.foregroundColor: tintColor, .font: primaryFont]
            buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: tintColor, .font: primaryFont]
            navAppearance.buttonAppearance = buttonAppearance
            
            // 設定 navigation bar 建立自拍照按鈕外貌
            let doneButtonApperance = UIBarButtonItemAppearance(style: .done)
            buttonAppearance.normal.titleTextAttributes = [.foregroundColor: tintColor, .font: primaryFont]
            doneButtonApperance.highlighted.titleTextAttributes = [.foregroundColor: tintColor, .font: primaryFont]
            navAppearance.doneButtonAppearance = doneButtonApperance
            
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().tintColor = tintColor
            
            // 設定 tool bar 外貌
            let toolbarAppearance = UIToolbarAppearance()
            toolbarAppearance.buttonAppearance = buttonAppearance
            toolbarAppearance.doneButtonAppearance = doneButtonApperance
            UIToolbar.appearance().standardAppearance = toolbarAppearance
        }
        else {
            // 將 navigation bar 的 tintColor 指定為我們要的顏色
            UINavigationBar.appearance().tintColor = tintColor
            
            // 取得 navigation bar 的標籤外貌，使用參數 whenContainedInInstancesOf: 取得標籤在不同狀態下的外貌
            let navBarLabel = UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
            // 設定 navigation bar 標籤字體
            navBarLabel.font = primaryFont
            
            // 取得 navigation bar 外貌
            let navBar = UINavigationBar.appearance()
            // 設定 navigation bar 佈景主題
            navBar.titleTextAttributes = [.font: headerFont]
            
            
            // 取得標籤外貌
            let label = UILabel.appearance()
            // 設定 label 的字體
            label.font = primaryFont
            
            // 取得 navigation bar 按鈕外貌
            let barButton = UIBarButtonItem.appearance()
            // 設定按鈕文字的字體
            barButton.setTitleTextAttributes([.font: primaryFont], for: .normal)
            barButton.setTitleTextAttributes([.font: primaryFont], for: .highlighted)
            
            // 取得按鈕標籤外貌
            let buttonLabel = UILabel.appearance(whenContainedInInstancesOf: [UIButton.self])
            // 設定按鈕標籤字體
            buttonLabel.font = primaryFont
        }
    }
}

extension UIFont {
    convenience init?(familyName: String,
                      size: CGFloat = UIFont.systemFontSize,
                      variantName: String? = nil) {
        // NOTICE! 這邊是用來找到內部字型名稱的程式碼
        // 不過，如果有超過一個的字型家族含有
        // <familName> 或是第一個找到的字型不是我們
        // 想要找的字型，就會有錯誤發生
        
        // 採用這方法的原因，目的是把
        // 要用的內部字型顯示出來
        // 實務上的做法是直接指定完整的字型名稱就可以！！
        guard let name = UIFont.familyNames
                .filter({ $0.contains(familyName) })
                .flatMap({ UIFont.fontNames(forFamilyName: $0) })
                .filter({ variantName != nil ? $0.contains(variantName!) : true })
                .first else { return nil }
        
        self.init(name: name, size: size)
    }
}
