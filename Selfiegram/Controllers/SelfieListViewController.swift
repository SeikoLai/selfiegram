//
//  SelfieListViewController.swift
//  Selfiegram
//
//  Created by Sam Lai on 2022/1/26.
//

import UIKit

class SelfieListViewController: UITableViewController {
    
    // 我們要顯示的圖片物件清單
    var selfies: [Selfie] = []
    
   var detailViewController: DetailViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

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
            detailViewController = (controllers[controllers.count - 1] as? UINavigationController)?.topViewController as? DetailViewController
        }
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

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let selfie = selfies[indexPath.row]
        cell.textLabel?.text = selfie.title

        return cell
    }
}
