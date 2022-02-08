//
//  SelfieStoreTest.swift
//  SelfiegramTests
//
//  Created by Sam Lai on 2022/1/26.
//

import XCTest
@testable import Selfiegram
import UIKit
import CoreLocation

class SelfieStoreTest: XCTestCase {
    
    /// 一個輔助函式，用來產生含文字的圖片
    /// - Parameter text: 要顯示在圖片上的文字
    /// - Returns: 含有文字顯示於其上的圖片
    func createImage(text: String) -> UIImage {
        //  開始一個圖片背景
        UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
        
        // 再從這個函式回傳後，進行關閉圖片背景的工作
        defer {
            UIGraphicsEndImageContext()
        }
        
        // 建立一個 label
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.font = UIFont.systemFont(ofSize: 50)
        label.text = text
        
        // 把 label 畫在目前圖片背景的上面
        label.drawHierarchy(in: label.frame, afterScreenUpdates: true)
        
        // 回傳該圖片
        // (!表示必須成功得到一張圖片，否則會當掉)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    func testLocationSelfie() {
        // 東京都廳的地點資訊 35.6890864, 139.6897425
        let location = CLLocation(latitude: 35.6890864, longitude: 139.6897425)
        
        // 建立一個帶有圖片的新自拍照
        let newSelfie = Selfie(title: "Tokyo Metropolitan Government Building Selfie")
        let newImage = createImage(text: "🇯🇵")
        newSelfie.image = newImage
        
        // 將地點資訊儲存在自拍照中
        newSelfie.position = Selfie.Coordinate(location: location)
        
        // 將帶有地點的自拍照儲存起來
        do {
            try SelfieStore.shared.save(selfie: newSelfie)
        }
        catch {
            XCTFail("failed to save the location selfie")
        }
        
        // 從儲存的自拍清單中取出自拍照
        let loadedSelfie = SelfieStore.shared.load(id: newSelfie.id)
        
        XCTAssertNotNil(loadedSelfie?.position, "Loaded selfie shouldn't be nil")
        XCTAssertEqual(newSelfie.position, loadedSelfie?.position, "The position should be equal")
    }
    
    func testCreatingSelfie() {
        // Arrange（準備工作）
        let selfieTitle = "Creation Test Selfie"
        let newSelfie = Selfie(title: selfieTitle)
        
        // Act（測試）
        try? SelfieStore.shared.save(selfie: newSelfie)
        
        // Assert（檢查結果）
        let allSelfies = try! SelfieStore.shared.listSelfies()
        
        guard let _ = allSelfies.first(where: { $0.id == newSelfie.id })
        else {
            XCTFail("Selfies list should contain the one we just created.")
            return
        }
        
        XCTAssertEqual(selfieTitle, newSelfie.title)
    }
    
    func testSavingImage() throws {
        // Arrange
        let newSelfie = Selfie(title: "Selfie with image test")
        newSelfie.image = createImage(text: "♋️")
        
        // Act
        try SelfieStore.shared.save(selfie: newSelfie)
        
        // Assert
        let loadedImage = SelfieStore.shared.getImage(id: newSelfie.id)
        
        XCTAssertNotNil(loadedImage, "The image should be loaded.")
    }
    
    func testLoadingSelfie() throws {
        // Arrange
        let selfieTitle = "Test loading selfie"
        let newSelfie = Selfie(title: selfieTitle)
        try SelfieStore.shared.save(selfie: newSelfie)
        let id = newSelfie.id
        
        // Act
        let loadedSelfie = SelfieStore.shared.load(id: id)
        
        // Assert
        XCTAssertNotNil(loadedSelfie, "The selfie should be loaded")
        XCTAssertEqual(loadedSelfie?.id, newSelfie.id, "The loaded selfie should have the same ID")
        XCTAssertEqual(loadedSelfie?.created, newSelfie.created, "The loaded selfie should have the same creation date")
        XCTAssertEqual(loadedSelfie?.title, newSelfie.title, "The loaded selfie should have the same title")
    }
    
    func testDeletingSelfie() throws {
        // Arrange
        let newSelfie = Selfie(title: "Test deleting a selfie")
        try SelfieStore.shared.save(selfie: newSelfie)
        let id = newSelfie.id
        
        // Act
        let allSelfies = try SelfieStore.shared.listSelfies()
        try SelfieStore.shared.delete(id: id)
        let selfieList = try SelfieStore.shared.listSelfies()
        let loadedSelfie = SelfieStore.shared.load(id: id)
        
        // Assert
        XCTAssertEqual(allSelfies.count - 1, selfieList.count, "There should be one less selfie after deletion")
        XCTAssertNil(loadedSelfie, "Deleted selfie should be nil")
    }
}
