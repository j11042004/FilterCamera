//
//  CameraViewController.swift
//  ImagePickerManager
//
//  Created by Uran on 2018/7/6.
//  Copyright © 2018年 Uran. All rights reserved.
//  若先使用了 Photo 選擇

import UIKit
import AVFoundation
class CameraViewController: UIViewController {
    enum CameraType {
        case Video
        case Photo
    }
    @IBOutlet weak var captureButton: UIButton!{
        didSet{
            captureButton.layer.masksToBounds = false
            captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
            captureButton.layer.masksToBounds = true
        }
    }
    /// 相機畫面顯示 view
    @IBOutlet weak var cameraView: UIView! {
        didSet{
            cameraView.backgroundColor = UIColor.clear
        }
    }
    /// 錄影機畫面顯示 View
    @IBOutlet weak var videoView: UIView!
    
    // 選擇照片還是影片拍攝
    @IBOutlet weak var cameraControl: UISegmentedControl!{
        didSet {
            cameraControl.selectedSegmentIndex = 1
        }
    }
    @IBOutlet weak var flashItem: UIBarButtonItem!{
        didSet{
            flashItem.image = flashImg
        }
    }
    let flashImg = UIImage(named: "flash.png")
    let noFlashImg = UIImage(named: "noflash.png")
    
    var type : CameraType = CameraType.Photo
    let camera = Camera.sharedInstance
    let recoder = CameRecoder()
    // 模糊化的View
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
    lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recoder.prepareVideoCam(with: self.videoView) { (success) in
            
        }
        camera.prepare(With: .back) { (error) in
            if let error = error {
                print("Camera Prepare error :\(error.localizedDescription)")
            }
            self.camera.startCaptureFrame()
            do {
                try self.camera.displayPreview(on: self.cameraView)
            }catch {
                NSLog(error.localizedDescription)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 當轉向時會通知
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { (notifi) in
            self.camera.changePreviewLayerFrame()
        }
        switch type {
        case .Photo:
            self.camera.startCaptureFrame()
            break
        case .Video:
            recoder.startCaptureFrame()
            break
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.recoder.updatePreviewLayer()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 移除轉向通知
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        self.camera.stopCaptureFrame()
        self.recoder.startCaptureFrame()
    }
    
    
    @IBAction func switchCameraType(_ sender: UISegmentedControl) {
        self.blurView.frame = self.cameraView.frame
        self.view.addSubview(self.blurView)
        
        self.camera.stopCaptureFrame()
        self.recoder.stopCaptureFrame()
        
        if sender.selectedSegmentIndex == 0 {
            type = CameraType.Video
            self.view.bringSubviewToFront(self.videoView)
            self.recoder.startCaptureFrame()
        }else{
            type = CameraType.Photo
            self.view.bringSubviewToFront(self.cameraView)
            self.camera.startCaptureFrame()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.blurView.removeFromSuperview()
        }
    }
    /// 照相或錄影
    @IBAction func captureFrame(_ sender: UIButton) {
        switch type {
        case .Photo:
            self.captureImage()
            break
        case .Video :
            self.recoder.setFilter(with: 0)
            NSLog("開始結束錄影")
            break
        }
    }
    // 更換鏡頭前後
    @IBAction func switchCamera(_ sender: UIBarButtonItem) {
        switch type {
        case .Photo:
            do {
                try camera.switchCameras()
            } catch {
                print("switchCameras error :\(error.localizedDescription)")
            }
            break
        case .Video:
            self.recoder.switchPosition()
            break
        }
        
    }
    
    @IBAction func switchFlash(_ sender: Any) {
        self.camera.flashMode = self.camera.flashMode == .on ? .off : .on
        switch self.camera.flashMode {
        case .on:
            flashItem.image = noFlashImg
            break
        default :
            flashItem.image = flashImg
            break
        }
    }
    
    func captureImage(){
        self.camera.captureImage { (image, error) in
            if let error = error {
                NSLog("capture image error :\(error.localizedDescription)")
                return
            }

            let photoVC = UIStoryboard(name: "Camera", bundle: Bundle(for: CameraViewController.self)).instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
            photoVC.photo = image
            self.navigationController?.pushViewController(photoVC, animated: true)
        }
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    override var preferredScreenEdgesDeferringSystemGestures : UIRectEdge {
        return .top
    }
}
