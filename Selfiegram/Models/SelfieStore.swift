//
//  SelfieStore.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/1/26.
//

import Foundation
import UIKit.UIImage

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
}

enum SelfieStoreError: Error {
    case cannotSaveImage(UIImage?)
}

final class SelfieStore {
    static let shared = SelfieStore()
    
    /// 用 ID 取得一張圖片，取得後會存在記憶體中供之後使用
    /// - Parameter id: 你想要的那張自拍照 ID
    /// - Returns: 該張自拍照的圖片，若不存在的話，回傳 nil
    func getImage(id: UUID) -> UIImage? {
        return nil
    }
    
    /// 將圖片儲存
    /// - Parameters:
    ///   - id: 你想要存的那張自拍照 ID
    ///   - image: 你想存的那張照片
    func setImage(id: UUID, image: UIImage?) throws {
        throw SelfieStoreError.cannotSaveImage(image)
    }
    
    /// 取出的自拍照清單
    /// - Returns: 一個 Array，包含之前存過的所有自拍照
    func listSelfies() throws -> [Selfie] {
        return []
    }
    
    ///  刪除一張自拍照，還有對應的圖片
    ///  這個函式從傳入的自拍照取得ID
    ///  並將它傳給另外一個版本的刪除函式
    /// - Parameter selfie: 你想刪除的自拍照
    func delete(selfie: Selfie) throws {
        throw SelfieStoreError.cannotSaveImage(nil)
    }
    
    /// 刪除一張自拍照，還有對應的圖片
    /// - Parameter id: 你想刪除的自拍照ID
    func delete(id: UUID) throws {
        throw SelfieStoreError.cannotSaveImage(nil)
    }
    
    /// 試著從記憶體中讀出一張自拍照
    /// - Parameter id: 從記憶體中讀出的自拍照 ID
    /// - Returns: ID 匹配的那張自拍照，如果不存在的話，回傳 nil
    func load(id: UUID) -> Selfie? {
        return nil
    }
    
    /// 試著儲存一張自拍照
    /// - Parameter selfie: 要儲存的自拍照
    func save(selfie: Selfie) throws {
        throw SelfieStoreError.cannotSaveImage(nil)
    }
}
