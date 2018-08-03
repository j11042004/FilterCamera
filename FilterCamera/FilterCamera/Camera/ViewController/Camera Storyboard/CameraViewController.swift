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
    @IBOutlet weak var cameraView: UIView! {
        didSet{
            cameraView.backgroundColor = UIColor.clear
        }
    }
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
    
    // 模糊化的View
    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
    lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
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
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: nil) { (notifi) in
            self.camera.changePreviewLayerFrame()
        }
        self.camera.startCaptureFrame()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 移除轉向通知
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        self.camera.stopCaptureFrame()
    }
    
    
    @IBAction func switchCameraType(_ sender: UISegmentedControl) {
        self.blurView.frame = self.cameraView.frame
        self.view.addSubview(self.blurView)
        
        self.camera.stopCaptureFrame()
        
        if sender.selectedSegmentIndex == 0 {
            type = CameraType.Video
            
        }else{
            type = CameraType.Photo
            self.camera.startCaptureFrame()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.blurView.removeFromSuperview()
        }
    }
    
    @IBAction func captureFrame(_ sender: UIButton) {
        switch type {
        case .Photo:
            self.captureImage()
            break
        case .Video :
            
            break
        }
    }
    
    @IBAction func switchCamera(_ sender: UIBarButtonItem) {
        do {
            try camera.switchCameras()
        } catch {
            print("switchCameras error :\(error.localizedDescription)")
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
            image?.savedInPhotoLibrary()
            photoVC.photo = image
            self.navigationController?.pushViewController(photoVC, animated: true)
        }
    }
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
        return .top
    }
}
