//
//  SelfieStore.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/1/26.
//

import Foundation
import UIKit
import CoreLocation.CLLocation

class Selfie: Codable {
    
    // 何時拍的照片
    let created: Date
    
    // 唯一ID，用來將這張自拍照連結到記憶體的照片
    let id: UUID
    
    // 自拍照名稱
    var title = "New Selfie!"
    
    // 這張自拍照在記憶體中的圖片
    var image: UIImage? {
        get {
            return SelfieStore.shared.getImage(id: self.id)
        }
        set {
            try? SelfieStore.shared.setImage(id: self.id, image: newValue)
        }
    }
    
    init(title: String) {
        self.title = title
        
        // 目前時間
        self.created = Date()
        // 一個新的 UUID
        self.id = UUID()
    }
    
    struct Coordinate: Codable, Equatable {
        var latitude: Double
        var longitude: Double
        
        // 為了符合 Equatable 協定，需要實作相等判斷方法
        public static func == (lhs: Selfie.Coordinate, rhs: Selfie.Coordinate) -> Bool {
            return lhs.latitude == rhs.latitude && lhs.latitude == rhs.latitude
        }
        
        // 實作較輕量的結構，用來儲存、載入並取得CLLocation
        var location: CLLocation {
            get {
                return CLLocation(latitude: self.latitude,
                                  longitude: self.longitude)
            }
            set {
                self.latitude = newValue.coordinate.latitude
                self.longitude = newValue.coordinate.longitude
            }
        }
        
        // 使用 CLLocation 初始
        init(location: CLLocation) {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
    }
    
    // 拍攝自拍照的地點
    var position: Coordinate?
}

enum SelfieStoreError: Error {
    case cannotSaveImage(UIImage?)
}

final class SelfieStore {
    static let shared = SelfieStore()
    
    private var imageCache: [UUID: UIImage] = [:]
    
    var documentsFolder: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
    }
    
    /// 用 ID 取得一張圖片，取得後會存在記憶體中供之後使用
    /// - Parameter id: 你想要的那張自拍照 ID
    /// - Returns: 該張自拍照的圖片，若不存在的話，回傳 nil
    func getImage(id: UUID) -> UIImage? {
        // 如果快取中有圖片，則使用快取中的圖片
        if let image = imageCache[id] {
            return image
        }
        
        // 找出圖片位置
        let imageURL = self.documentsFolder.appendingPathComponent("\(id.uuidString)-image.jpg")
        
        // 從檔案中取資料，失敗回傳 nil
        guard let imageData = try? Data(contentsOf: imageURL)
        else {
            return nil
        }
        
        // 從資料中取得圖片，失敗回傳 nil
        guard let image = UIImage(data: imageData)
        else {
            return nil
        }
        
        // 將已載入的圖片存入快取
        imageCache[id] = image
        
        // 回傳已載入的圖片
        return image
    }
    
    /// 將圖片儲存
    /// - Parameters:
    ///   - id: 你想要存的那張自拍照 ID
    ///   - image: 你想存的那張照片
    func setImage(id: UUID, image: UIImage?) throws {
        // 取得檔案名稱
        let fileName = "\(id.uuidString)-image.jpg"
        
        // 取得檔案位置
        let destinationURL = self.documentsFolder.appendingPathComponent(fileName)
        
        if let image = image {
            // 得到圖片將其儲存
            // 嘗試將圖片轉為 JPEG
            guard let data = image.jpegData(compressionQuality: 0.9)
            else {
                // 失敗就丟出錯誤
                throw SelfieStoreError.cannotSaveImage(image)
            }
            
            // 嘗試將資料寫出
            try data.write(to: destinationURL)
        }
        else {
            // image 是 nil 則表示刪除圖片
            // 嘗試執行刪除圖片
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        // 將圖片放到快取，如果圖片不存在(nil)，代表刪除快取儲存的照片
        imageCache[id] = image
    }
    
    /// 取出的自拍照清單
    /// - Returns: 一個 Array，包含之前存過的所有自拍照
    func listSelfies() throws -> [Selfie] {
        // 取得 Documents 目錄下的檔案清單
        let contents = try FileManager.default.contentsOfDirectory(at: self.documentsFolder, includingPropertiesForKeys: nil)
        
        // 取得所有副檔名為 'json' 的檔案
        // 將他們載入成為 data，並從 JSON 中解碼
        return try contents.filter { $0.pathExtension == "json" }
        .map { try Data(contentsOf: $0) }
        .map { try JSONDecoder().decode(Selfie.self, from: $0) }
    }
    
    ///  刪除一張自拍照，還有對應的圖片
    ///  這個函式從傳入的自拍照取得ID
    ///  並將它傳給另外一個版本的刪除函式
    /// - Parameter selfie: 你想刪除的自拍照
    func delete(selfie: Selfie) throws {
        try delete(id: selfie.id)
    }
    
    /// 刪除一張自拍照，還有對應的圖片
    /// - Parameter id: 你想刪除的自拍照ID
    func delete(id: UUID) throws {
        // 取得資料檔案名稱
        let selfieDataFileName = "\(id.uuidString).json"
        
        // 取得圖片檔案名稱
        let imageFileName = "\(id.uuidString)-image.jpg"
        
        // 取得資料路徑
        let selfieDataURL = self.documentsFolder.appendingPathComponent(selfieDataFileName)
        
        // 取得圖片路徑
        let imageURL = self.documentsFolder.appendingPathComponent(imageFileName)
        
        // 如果檔案存在就刪除
        if FileManager.default.fileExists(atPath: selfieDataURL.path) {
            try FileManager.default.removeItem(at: selfieDataURL)
        }
        if FileManager.default.fileExists(atPath: imageURL.path) {
            try FileManager.default.removeItem(at: imageURL)
        }
        
        // 刪除快取中的圖片
        imageCache[id] = nil
    }
    
    /// 試著從記憶體中讀出一張自拍照
    /// - Parameter id: 從記憶體中讀出的自拍照 ID
    /// - Returns: ID 匹配的那張自拍照，如果不存在的話，回傳 nil
    func load(id: UUID) -> Selfie? {
        // 取得資料名稱
        let dataFileName = "\(id.uuidString).json"
        
        // 取得資料路徑
        let dataURL = self.documentsFolder.appendingPathComponent(dataFileName)
        
        // 試圖載入檔案中的資料
        // 再嘗試將資料轉成圖片
        // 然後回傳圖片
        // 如果失敗就回傳 nil
        if let data = try? Data(contentsOf: dataURL),
           let selfie = try? JSONDecoder().decode(Selfie.self, from: data) {
            return selfie
        }
        else {
            return nil
        }
    }
    
    /// 試著儲存一張自拍照
    /// - Parameter selfie: 要儲存的自拍照
    func save(selfie: Selfie) throws {
        // 將 selfie 轉成 data
        let selfieData = try JSONEncoder().encode(selfie)
        
        // 取得檔案名稱
        let fileName = "\(selfie.id.uuidString).json"
        
        // 取黨檔案路徑
        let destinationURL = self.documentsFolder.appendingPathComponent(fileName)
        
        // 將 selfie 寫入指定位置
        try selfieData.write(to: destinationURL)
    }
}
