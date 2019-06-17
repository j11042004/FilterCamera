//
//  Camera.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/13.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import AVFoundation

typealias CaptureCompletion = (_ image : UIImage? , _ error : Error?) -> Void

class Camera: NSObject {
    static let sharedInstance = Camera()
    /// 處理相機輸入輸出的資料
    let session : AVCaptureSession = AVCaptureSession()
    var sessionPrepare = false
    // 相機輸出的資料
    var photoOutput : AVCapturePhotoOutput?
    /// 顯示鏡頭輸入的 Layer
    var previewLayer : AVCaptureVideoPreviewLayer?
    /// 前鏡頭
    var frontCamera: AVCaptureDevice?
    /// 前鏡頭輸入
    var frontCameraInput : AVCaptureDeviceInput?
    /// 後鏡頭
    var backCamera: AVCaptureDevice?
    /// 後鏡頭輸入
    var backCameraInput : AVCaptureDeviceInput?
    /// 閃光燈開關
    var flashMode : AVCaptureDevice.FlashMode = .off
    /// 鏡頭前後
    var currentCameraPosition : CameraPosition?
    // 背境頭種類
    let backCameraType : AVCaptureDevice.DeviceType = UIDevice.current.modelName == .iPhoneX ? .builtInDualCamera : .builtInWideAngleCamera
    /// 前鏡頭總類
    let frontCameraType : AVCaptureDevice.DeviceType = UIDevice.current.modelName == .iPhoneX ? .builtInTrueDepthCamera: .builtInWideAngleCamera
    // 相片轉向的角度
    var fixAngles : Double = 0
    
    var captureClosure : CaptureCompletion?
}

extension Camera {
    // 相機的準備
    public func prepare(With position : CameraPosition ,comletion : @escaping (_ error : Error?)->Void){
        var devicePosition : AVCaptureDevice.Position
        switch position {
        case .front:
            devicePosition = .front
            break
        case .back :
            devicePosition = .back
            break
        }
        func caonfigureCaptureDevice() throws {
            // 預設 Session 是背景相機
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [frontCameraType , backCameraType], mediaType: AVMediaType.video, position: devicePosition)
            self.currentCameraPosition = position
            // 把 Cameras 內的 nil 過濾
            let cameras = session.devices.compactMap { $0 }
            guard !cameras.isEmpty else {
                throw CameraError.noCamerasAvailable(message: "所有 Camera 都無效")
            }
            // 從所有相機中取的所有的鏡頭
            for camera in cameras {
                if camera.position == .front{
                    self.frontCamera = camera
                }
                if camera.position == .back{
                    self.backCamera = camera
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
            // 判斷兩個 Camera 是否 Nil，若 Nil 就自行設定
            self.frontCamera =
                self.frontCamera != nil ? // 判斷前景鏡頭是否為 nil
                    self.frontCamera : // 若不是就設為自己
                    AVCaptureDevice.default(frontCameraType, for: .video, position: .front)
            self.backCamera =
                self.backCamera != nil ? // 判斷背景鏡頭是否為 nil
                    self.backCamera : // 若不是就設為自己
                    AVCaptureDevice.default(backCameraType, for: .video, position: .back)
        }
        /// 管理輸入鏡頭
        func confugureDeviceInputs() throws{
            // 判斷 鏡頭的輸入 是否可行
            if let frontCamera = self.frontCamera  {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            }
            if let backCamera = self.backCamera {
                self.backCameraInput = try AVCaptureDeviceInput(device: backCamera)
            }
            
            // 判斷哪個鏡頭可以被加入
            if self.session.canAddInput(self.backCameraInput!) &&
                self.currentCameraPosition == .back {
                self.session.addInput(self.backCameraInput!)
                self.currentCameraPosition = .back
            }
            if self.session.canAddInput(self.frontCameraInput!) &&
                self.currentCameraPosition == .front{
                self.session.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            }
            print("inputs : \(self.session.inputs.count)")
            
            if self.session.inputs.count == 0 {
                throw CameraError.inputsAreInvalid(message: "前鏡頭或後鏡頭都務法被加入")
            }
            
        }
        /// 管理影像輸出
        func configurePhotoOutput() throws{
            
            self.photoOutput = AVCapturePhotoOutput()
            // 設定輸出的格式為 jpeg
            let setting = [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])]
            // 設定準備的設定
            self.photoOutput!.setPreparedPhotoSettingsArray(setting, completionHandler: nil)
            // session 加入 output
            if self.session.canAddOutput(self.photoOutput!){
                self.session.addOutput(self.photoOutput!)
            }
            self.sessionPrepare = true
        }
        // MARK: 開始執行準備Camera
        DispatchQueue(label: "prepare").async {
            do{
                try caonfigureCaptureDevice()
                try confugureDeviceInputs()
                try configurePhotoOutput()
            }catch{
                print("error : \(error.localizedDescription)")
                DispatchQueue.main.async {
                    comletion(error)
                }
                return
            }
            DispatchQueue.main.async {
                comletion(nil)
            }
        }
    }
    /// 開始擷取畫面
    public func startCaptureFrame(){
        if self.sessionPrepare && !self.session.isRunning {
            self.session.startRunning()
        }
    }
    /// 停止擷取畫面
    public func stopCaptureFrame(){
        self.session.stopRunning()
    }
    
    /// 設定要顯示的 Layer
    public func displayPreview(on view : UIView) throws{
        guard self.sessionPrepare else {
            throw CameraError.captureSessionIsMissing(message: "self.session prepare not finished")
        }
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        // 設定 layer 布滿的狀態
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        // 更改 prebiewLayer 的 Frame
        self.previewLayer?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
    }
    /// 更換 PreviewLayer 的 Frame
    public func changePreviewLayerFrame() {
        guard self.previewLayer != nil ,
            let superLayer = self.previewLayer?.superlayer
        else {
            return
        }
        UIView.animate(withDuration: 0.1) {
            self.previewLayer?.frame = CGRect(x: 0, y: 0, width: superLayer.frame.width, height: superLayer.frame.height)
            if let angles =  self.previewLayer?.transformOrientation(){
                self.fixAngles = angles
            }
        }
    }
}
extension Camera{
    /// 更換鏡頭
    public func switchCameras() throws {
        // 確保 CaptureSession 正常運行，確認正在使用的鏡頭位址
        guard let currentCameraPosition = currentCameraPosition,
            self.session.isRunning
            else {
                throw CameraError.captureSessionIsMissing(message: "currentCameraPosition may be is nil or session stop Running")
        }
        
        // 告知 Capture Session 開始設定
        self.session.beginConfiguration()
        
        /// 轉成前鏡頭
        func switchToFrontCamera() throws {
            // 判斷是否包含後鏡頭 ， 前鏡頭是否存在
            guard let backCameraInput = self.backCameraInput,
                self.session.inputs.contains(backCameraInput),
                let frontCamera = self.frontCamera
                else {
                    throw CameraError.invalidOperation(message: "Front Camera is nil or Session not contain backCameraInput")
            }
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            // capture Session 移除後鏡頭
            self.session.removeInput(backCameraInput)
            // 判斷是否能新增前鏡頭
            if self.session.canAddInput(self.frontCameraInput!) {
                self.session.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            }else {
                throw CameraError.invalidOperation(message: "front camera is nil")
            }
        }
        /// 轉成後鏡頭
        func switchToBackCamera() throws {
            
            guard let frontCameraInput = self.frontCameraInput,
                self.session.inputs.contains(frontCameraInput),
                let rearCamera = self.backCamera
                else {
                    throw CameraError.invalidOperation(message: "backCamera is nil or session not include frontCameraInput")
            }
            
            self.backCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            
            self.session.removeInput(frontCameraInput)
            if self.session.canAddInput(self.backCameraInput!) {
                self.session.addInput(self.backCameraInput!)
                self.currentCameraPosition = .back
            }else {
                throw CameraError.invalidOperation(message: "can't add backCameraInput")
            }
        }
        
        //更換鏡頭選項
        switch currentCameraPosition {
        case .front:
            try switchToBackCamera()
        case .back:
            try switchToFrontCamera()
        }
        // 提交或儲存設定好的 Capture Session
        self.session.commitConfiguration()
    }
    
    /// 取得相片
    public func captureImage( complete : @escaping CaptureCompletion){
        self.captureClosure = complete
        guard self.session.isRunning,
            self.sessionPrepare
            else {
            self.captureClosure?(nil , CameraError.captureSessionIsMissing(message: "self.session not running or it not prepare finished"))
            return
        }
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}
extension Camera : AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{
            self.captureClosure?(nil , error)
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            print("Capture imageData is nil")
            let dataError = NSError(domain: "photo file data is nil", code: -1, userInfo: nil) as Error
            self.captureClosure?(nil , dataError)

            self.startCaptureFrame()
            return
        }
        
        guard var photo = UIImage(data: imageData) else{
            NSLog("Capture image fail")
            let photoError = NSError(domain: "photo is nil", code: -1, userInfo: nil) as Error
            self.captureClosure?(nil , photoError)

            self.startCaptureFrame()
            return
        }
        if self.fixAngles != 0 {
            // 進行圖片轉向
            photo = photo.rotate(radians: self.fixAngles)
        }
        if self.currentCameraPosition == .front{
            //進行左右翻轉
            photo = photo.orientationFlip(orientation: .leftMirrored)
        }
        
        self.captureClosure?(photo , error)
        self.startCaptureFrame()
    }
}


extension Camera {
    public enum CameraPosition{
        case front
        case back
    }
}


