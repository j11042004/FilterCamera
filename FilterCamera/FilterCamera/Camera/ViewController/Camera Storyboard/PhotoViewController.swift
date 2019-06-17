//
//  PhotoViewController.swift
//  ImagePickerManager
//
//  Created by Uran on 2018/7/9.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    @IBOutlet weak var photoImageView: UIImageView!
    var photo : UIImage?
    @IBOutlet weak var filterView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        
        self.photoImageView.image = photo
        self.view.backgroundColor = .green
        self.tabBarController?.tabBar.isHidden = true
        let saveItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(saveImageInPhotoLibrary))
        self.navigationItem.rightBarButtonItems = [saveItem]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    /// 將相片存到相簿中
    @objc func saveImageInPhotoLibrary(){
        let alert = UIAlertController(title: nil, message: "是否要儲存照片", preferredStyle: .alert)
        let save = UIAlertAction(title: "儲存", style: .default) { [weak self](_) in
            self?.photo?.savedInPhotoLibrary(completion: { (success) in
                self?.savedAlert(With: success)
            })
        }
        let cancel = UIAlertAction(title: "退出", style: .cancel) { [weak self](_) in
            DispatchQueue.main.async {
                if self?.navigationController != nil {
                    self?.navigationController?.popViewController(animated: true)
                }else{
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        }
        alert.addAction(save)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    func savedAlert(With success : Bool){
        let message = success ? "儲存成功！" : "儲存失敗，請確認是否有開啟權限，允許本 app 存放圖片到相簿中！"
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "確定", style: .cancel) { [weak self](_) in
            DispatchQueue.main.async {
                if self?.navigationController != nil {
                    self?.navigationController?.popViewController(animated: true)
                }else{
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        }
        alert.addAction(cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
