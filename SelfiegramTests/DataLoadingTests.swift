//
//  DataLoadingTests.swift
//  SelfiegramTests
//
//  Created by Sam Lai on 2022/2/14.
//

import XCTest
@testable import Selfiegram

class DataLoadingTests: XCTestCase {

    override func setUpWithError() throws {
        // 移除所有 cache 資料
        let cacheURL = OverlayManager.cacheDirectoryURL
        
        // 取得 cache 資料失敗，測試失敗
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheURL,
                                                                          includingPropertiesForKeys: nil,
                                                                          options: []) else {
            XCTFail("Failed to list contents of directory \(cacheURL)")
            return
        }
        
        // 用來控制是否完成清空 cache
        var complete = true
        
        // 從 cache 中逐一刪除資料
        for file in contents {
            do {
                try FileManager.default.removeItem(at: file)
            } catch let error {
                print("Test setup: failed to remove item \(file); \(error)")
                // 如果刪除資料失敗，將 complete 設為 false
                complete = false
            }
        }
        
        // 如果 complete 不為 true，讓測試失敗
        if !complete {
            XCTFail("Failed to delete contents of cache")
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // 測試是否確實沒有任何疊加圖在 cache 中，cache 不存在也算成功
    func testNoOverlaysAvailable() {
        // Arrange（初始化）
        
        // Act（測試）
        let availableOverlays = OverlayManager.shared.availableOverlays()
        
        // Assert（檢查結果）
        XCTAssertEqual(availableOverlays.count, 0, "Available overlay should be empty")
    }

    // 測試可以正確地從伺服器下載疊加圖資訊
    func testGettingOverlayInfo() {
        // Arrange（初始化）
        let expectation = self.expectation(description: "Done downloading")
        
        // Act（測試）
        var loadedInfo: OverlayManager.OverlayList?
        var loadedError: Error?
        OverlayManager.shared.refreshOverlays { (info, error) in
            loadedInfo = info
            loadedError = error
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert（檢查結果）
        XCTAssertNotNil(loadedInfo, "Loaded information should not be empty")
        XCTAssertNil(loadedError, "Some error occur: \(loadedError!.localizedDescription)")
    }
    
    // 測試 OverlayManager 可以下載疊加圖資訊，讓它們達到可用狀態
    func testDownloadingOverlays() {
        // Arrange（初始化）
        let loadingComplete = self.expectation(description: "Download done")
        var availableOverlays: [Overlay] = []
        
        // Act（測試）
        OverlayManager.shared.loadOverlayAssets(refresh: true) {
            availableOverlays = OverlayManager.shared.availableOverlays()
            loadingComplete.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
        
        // Assert（檢查結果）
        XCTAssertNotEqual(availableOverlays.count, 0, "Available overlays should not be empty")
    }
    
    // 測試 OverlayManager 建立時就能取得 cache 中的疊加圖
    func testDownloadedOverlaysAreCached() {
        // Arrange（初始化）
        let downloadingOverlayManager = OverlayManager()
        let downloadExpectation = self.expectation(description: "Data downloaded")
        
        // 開始下載
        downloadingOverlayManager.loadOverlayAssets(refresh: true, completion: {
            downloadExpectation.fulfill()
        })
        
        // 等待下載完成
        waitForExpectations(timeout: 10.0, handler: nil)
        
        // Act（測試）
        
        // 用初始化一個新的 OverlayManager 模擬啟動的狀態，它能存取之前下載的檔案
        let cacheTestOverlayManager = OverlayManager()
        
        // Assert（驗證結果）
        XCTAssertNotEqual(cacheTestOverlayManager.availableOverlays().count, 0, "Cached overlays should not be empty")
        XCTAssertEqual(downloadingOverlayManager.availableOverlays().count, cacheTestOverlayManager.availableOverlays().count, "Both overlay managers' available overlays should be equal")
    }
}
