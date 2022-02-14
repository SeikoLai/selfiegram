//
//  OverlayStore.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/2/14.
//

import Foundation
import UIKit.UIImage

enum OverlayManagerError: Error {
    // 無法下載的錯誤
    case noDataLoaded
    // 下載後的圖層無法解析
    case cannotParseData(underlyingError: Error)
}

struct OverlayInformation: Codable {
    let icon: String
    let leftImage: String
    let rightImage: String
}

final class OverlayManager {
    // 疊加曾類別主要介面
    static let shared = OverlayManager()
    
    // 使用型態別名，節省之後打字時間同時提升可讀性
    typealias OverlayList = [OverlayInformation]
    private var overlayInfo: OverlayList
    
    // 基本的 URL 儲存有所疊加資料的位置
    static let downloadURLBase = URL(string: "https://raw.githubusercontent.com/thesecretlab/learning-swift-3rd-ed/master/Data/")
    // 各疊加層的檔案位置
    static let overlayListURL = URL(string: "overlays.json", relativeTo: OverlayManager.downloadURLBase)!
    
    // 建立 cache 目錄
    static var cacheDirectoryURL: URL {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory,
                                                               in: .userDomainMask).first else {
            fatalError("Cache directory not found! This should not happen!")
        }
        return cacheDirectory
    }
    
    // 建立暫存目錄中疊加層資料檔案位置
    static var cachedOverlayListURL: URL {
        return cacheDirectoryURL.appendingPathComponent("overlays.json",
                                                        isDirectory: false)
    }
    
    // 回傳用來下載指定名稱圖檔的 URL
    func urlForAsset(named assetName: String) -> URL? {
        return URL(string: assetName, relativeTo: OverlayManager.downloadURLBase)
    }
    
    // 回傳暫存目錄中影像檔案的 URL
    func cachedUrlForAsset(named assetName: String) -> URL? {
        return URL(string: assetName, relativeTo: OverlayManager.cacheDirectoryURL)
    }
    
    init() {
        // 建立疊加層資料陣列
        do {
            // 從 cache 取得疊加層資料
            let overlayListData = try Data(contentsOf:  OverlayManager.cachedOverlayListURL)
            // 將 cache 資料轉成 OverlayList 型態
            self.overlayInfo = try JSONDecoder().decode(OverlayList.self, from: overlayListData)
        } catch {
            // 如果 cache 沒有疊加層資料，建立空的陣列
            self.overlayInfo = []
        }
    }
    
    // 回傳可用的疊加圖
    func availableOverlays() -> [Overlay] { return overlayInfo.compactMap{ Overlay(info: $0) } }
    
    // 從伺服器下載疊加圖清單的圖片
    func refreshOverlays(completion: @escaping (OverlayList?, Error?) -> Void) {
        // 建立下載資料的工作
        URLSession.shared.dataTask(with: OverlayManager.overlayListURL) { data, response, error in
            
            // 下載錯誤或是拿到 nil 資料就報出錯誤
            if let error = error {
                print("Failed to download \(OverlayManager.overlayListURL): \(error)")
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, OverlayManagerError.noDataLoaded)
                return
            }
            
            // 將取得的 data 放入 cache
            do {
                try data.write(to: OverlayManager.cachedOverlayListURL)
            } catch let error {
                print("Failed to write data to \(OverlayManager.cachedOverlayListURL) ; reason: \(error)")
                completion(nil, error)
            }
            
            // 解析資料並儲存到本地
            do {
                let overlayList = try JSONDecoder().decode(OverlayList.self, from: data)
                
                self.overlayInfo = overlayList
                
                completion(self.overlayInfo, nil)
                return
            } catch let decodeError {
                completion(nil, OverlayManagerError.cannotParseData(underlyingError: decodeError))
            }
        }.resume()
    }
    
    // 用於協調多個同時下載工作的 group
    private let loadingDispatchGroup = DispatchGroup()
    
    // 下載所有疊加圖會用到的資料，如果重整（refresh 為 true）時，
    // 疊加圖清單會更新
    func loadOverlayAssets(refresh: Bool = false, completion: @escaping () -> Void) {
        
        // 如果被告知要重整，就執行重整函式 -refreshOverlays
        // 並將 refresh 設為 false ，再次執行這函式
        if refresh {
            self.refreshOverlays(completion: { (overlays, error) in
                self.loadOverlayAssets(refresh: false, completion: completion)
            })
            return
        }
        
        // 幫每個已知的疊加圖下載資料
        for info in overlayInfo {
            // 每個疊加圖都有三個資料要要下載
            let names = [info.icon, info.leftImage, info.rightImage]
            
            // 建立 tuple 存放資料
            // 我們需要設定每個資料：
            // 1. 從哪裡取得
            // 2. 要存放到什麼地方
            typealias TaskURL = (source: URL, destination: URL)
            // 將資料以陣列儲存
            let taskURLs: [TaskURL] = names.compactMap{
                // 取得資料來源 URL，如果失敗回傳 nil
                guard let sourceURL = URL(string: $0, relativeTo: OverlayManager.downloadURLBase) else {
                    return nil
                }
                
                // 取得要 cache 資料的 URL，失敗回傳 nil
                guard let destinationURL = URL(string: $0, relativeTo: OverlayManager.cacheDirectoryURL) else {
                    return nil
                }
                
                return (source: sourceURL, destination: destinationURL)
            }
            
            // 開始處理疊加圖
            for taskURL in taskURLs {
                // 呼叫 'enter' 會讓 dispatch group 註冊一個未完成的工作
                loadingDispatchGroup.enter()
                
                // 開始下載
                URLSession.shared.dataTask(with: taskURL.source) { (data, response, error) in
                    
                    defer {
                        // 工作已完成，通知 dispatch group
                        self.loadingDispatchGroup.leave()
                    }
                    
                    guard let data = data else {
                        print("Failed to download \(taskURL.source): \(error!)")
                        return
                    }
                    
                    // 取得資料並放入 cache
                    do {
                        try data.write(to: taskURL.destination)
                    } catch let error {
                        print("Failed to write to \(taskURL.destination): \(error)")
                    }
                }.resume()
            }
            
            // 等待所有的下載完成，執行完成程式碼區塊
            loadingDispatchGroup.notify(queue: .main) {
                completion()
            }
        }
    }
}

// 疊加圖 Overlay 是一個用來包裝圖片的容器
// 用來顯示一道選定的眉毛給使用者
struct Overlay {
    // 眉毛可選清單中的圖片
    let previewIcon: UIImage
    
    // 用來畫在左右眉毛上的圖片
    let leftImage: UIImage
    let rightImage: UIImage
    
    // 建立含有指定名稱圖片的疊加圖
    // 圖片必須被下載，並且儲存在 cache 中
    // 否則的話建構器回傳 nil
    init?(info: OverlayInformation) {
        // 建立指到 cache 中圖片的 URL
        guard let previewURL = OverlayManager.shared.cachedUrlForAsset(named: info.icon),
              let leftURL = OverlayManager.shared.cachedUrlForAsset(named: info.leftImage),
              let rightURL = OverlayManager.shared.cachedUrlForAsset(named: info.rightImage) else {
                  return nil
              }
        
        // 試圖從 cache 中的 URL 取得圖片
        // 如果失敗回傳 nil
        guard let previewImage = UIImage(contentsOfFile: previewURL.path),
              let leftImage = UIImage(contentsOfFile: leftURL.path),
              let rightImage = UIImage(contentsOfFile: rightURL.path) else {
                  return nil
              }
        
        // 取得圖片，進行儲存
        self.previewIcon = previewImage
        self.leftImage = leftImage
        self.rightImage = rightImage
    }
}
