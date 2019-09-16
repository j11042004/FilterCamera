//
//  CameRecoder.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/20.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreImage
import Photos
// 濾鏡的方法
enum FilterName:String {
    case none = ""
    case colorInvert = "CIColorInvert"
    /// 反色
    case photoEffectMono = "CIPhotoEffectMono"
    case photoEffectInstant = "CIPhotoEffectInstant"
    case photoEffectTransfer = "CIPhotoEffectTransfer"
    /// 褐色濾鏡
    case sepiaTone = "CISepiaTone"
    /// 曝光濾鏡
    case exposureAdjust = "CIExposureAdjust"
    /// 單色濾鏡
    case colorMonochrome = "CIColorMonochrome"
    /// 陰影平衡
    case highlightShadowAdjust = "CIHighlightShadowAdjust"
}


class CameRecoder: NSObject {
    public static let sharedInstance = CameRecoder()
    private var session : AVCaptureSession = AVCaptureSession()
    private var cameraDeviceInput : AVCaptureDeviceInput?
    private var cameraDevice : AVCaptureDevice?
    private var cameraPosition : AVCaptureDevice.Position = .back
    // 音訊的輸入輸出
    private var audioInput : AVCaptureInput?
    private var audioOutput : AVCaptureOutput?
    /// 要顯示的 Layer
    private var previewLayer : CALayer!
    /// session 是否準備好
    private var capturePrepare = false
    
    /// 背景相機種類
    let backCameraType : AVCaptureDevice.DeviceType = UIDevice.current.modelName == .iPhoneX ? .builtInDualCamera : .builtInWideAngleCamera
    /// 前景相機種類
    let frontCameraType : AVCaptureDevice.DeviceType = UIDevice.current.modelName == .iPhoneX ? .builtInTrueDepthCamera: .builtInWideAngleCamera
    /// 濾鏡
    private var filter : CIFilter? = CIFilter(name: FilterName.none.rawValue)
    
    let filters : [String] = {
        return [FilterName.none.rawValue,
                FilterName.colorInvert.rawValue,
                FilterName.photoEffectMono.rawValue,
//                FilterName.photoEffectInstant.rawValue,
                FilterName.photoEffectTransfer.rawValue,
                FilterName.sepiaTone.rawValue,
//                FilterName.exposureAdjust.rawValue,
//                FilterName.colorMonochrome.rawValue,
                FilterName.highlightShadowAdjust.rawValue]
    }()
    let filterNames : [String] = {
        return ["原圖",
                "負片效果",
                "黑白效果",
//                FilterName.photoEffectInstant.rawValue,
                "舊化效果",
                "棕色化效果",
//                FilterName.exposureAdjust.rawValue,
//                FilterName.colorMonochrome.rawValue,
                "陰影平衡"
        ]
    }()
    /// 將 Buffer 轉成 CIImage
    private lazy var context : CIContext = {
        // 讓 GPU 去執行 濾鏡
        let eagleContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        let options = [CIContextOption.workingColorSpace : NSNull()]
        return CIContext(eaglContext: eagleContext!, options: options)
    }()
    
    //MARK: - AssetWriter
    private var assetWriter : AVAssetWriter?
    private var assetWriterPixelBufferInput : AVAssetWriterInputPixelBufferAdaptor?
    private var audioWritter : AVAssetWriterInput?
    
    //MARK: - Vidoe Records
    /// 是否正在錄影
    private var isRecording : Bool = false
    private var isPaused : Bool = false
    private var currentSampleTime : CMTime?
    private var currentVideoDimensions : CMVideoDimensions?
    
    /// 準備錄影機
    public func prepareVideoCam(with view : UIView ,completion : (_ prepare : Bool)->Void){
        previewLayer = CALayer()
        previewLayer.anchorPoint = CGPoint.zero
        previewLayer.bounds = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        self.session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        // Session 輸入錄製的影片
        self.cameraDevice = AVCaptureDevice.default(self.backCameraType, for: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let deviceInput = try! AVCaptureDeviceInput(device: self.cameraDevice!)
        if self.session.canAddInput(deviceInput){
            self.session.addInput(deviceInput)
            self.cameraDeviceInput = deviceInput
            self.cameraPosition = .back
        }
        
        // Session 輸出錄製的聲音
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            let audioInput = try! AVCaptureDeviceInput(device: audioDevice)
            if self.session.canAddInput(audioInput){
                self.session.addInput(audioInput)
                self.audioInput = audioInput
            }
        }
        
        // Session 輸出錄製的影片
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings =
            [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput){
            session.addOutput(videoOutput)
        }
        // Session 輸出錄製的聲音
        let audioOutput = AVCaptureAudioDataOutput()
        if session.canAddOutput(audioOutput){
            session.addOutput(audioOutput)
            self.audioOutput = audioOutput
        }
        // 簽訂 影像輸出 與 聲音輸出 Delegate
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "AudioQueue"))
        // AvassetWriter get Buffer Delegate
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        //MARK: 檢測人臉
        let faceMetaDataOutput = AVCaptureMetadataOutput()
        faceMetaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        if session.canAddOutput(faceMetaDataOutput){
            session.addOutput(faceMetaDataOutput)
            // 設定辨識人臉
            faceMetaDataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        }
        
        // session 套用設定
        session.commitConfiguration()
        self.capturePrepare = true
        completion(self.capturePrepare)
    }
    /// 開始 Session 擷取畫面
    public func startCaptureFrame(){
        if !self.session.isRunning && self.capturePrepare {
            DispatchQueue.main.async {
                self.session.startRunning()
            }
        }
    }
    
    /// 停止 Session 擷取畫面
    public func stopCaptureFrame(){
        DispatchQueue.main.async {
            self.session.stopRunning()
        }
    }
    /// 更新顯示畫面
    public func updatePreviewLayer(){
        guard self.previewLayer != nil ,
            let superLayer = self.previewLayer?.superlayer
            else {
                return
        }
        UIView.animate(withDuration: 0.1) {
            self.previewLayer?.frame = CGRect(x: 0, y: 0, width: superLayer.frame.width, height: superLayer.frame.height)
        }
    }
    /// 是否要錄製聲音
    public func recordAudio(with allow : Bool){
        /// 停止錄製聲音
        func stopRrcordAudio(){
            guard let output = self.audioOutput,
                let input = self.audioInput
                else { return }
            if self.session.inputs.contains(input) {
                self.session.removeInput(input)
            }
            if self.session.outputs.contains(output){
                self.session.removeOutput(output)
            }
            
        }
        /// 開始錄製聲音
        func startRrcorAudio(){
            guard let output = self.audioOutput,
                let input = self.audioInput
                else { return }
            if !self.session.inputs.contains(input) &&
                self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            if !self.session.outputs.contains(output) &&
                self.session.canAddOutput(output){
                self.session.addOutput(output)
            }
        }
        if allow{
            startRrcorAudio()
        }else{
            stopRrcordAudio()
        }
        session.commitConfiguration()
    }
    
    /// Frame 放大
    func roomIn() {
        guard let zoomFactor = self.cameraDevice?.videoZoomFactor,
            zoomFactor < 10.0
        else {
            return
        }
        let newRoomFactor = min(zoomFactor+1.0, 10.0)
        do {
            try self.cameraDevice?.lockForConfiguration()
            cameraDevice?.ramp(toVideoZoomFactor: newRoomFactor, withRate: 2.0)
            self.cameraDevice?.unlockForConfiguration()
        } catch  {
            print("lockForConfiguration error : \(error.localizedDescription)")
        }
    }
    /// Frame 縮小
    func roomOut(){
        guard let zoomFactor = self.cameraDevice?.videoZoomFactor,
            zoomFactor >= 1.0
            else {
                return
        }
        let newRoomFactor = max(zoomFactor-1.0, 1.0)
        do {
            try self.cameraDevice?.lockForConfiguration()
            cameraDevice?.ramp(toVideoZoomFactor: newRoomFactor, withRate: 2.0)
            self.cameraDevice?.unlockForConfiguration()
        } catch  {
            print("lockForConfiguration error : \(error.localizedDescription)")
        }
    }
    
    /// 開始錄影
    ///
    /// - Returns: 是否正在錄影
    public func startRecord() -> Bool{
        if self.isRecording {
            return self.isRecording
        }
        self.isPaused = false
        self.createWriter()
        // 判斷 assetWriter 與 currentSampleTime 是否為 nil
        guard self.assetWriter != nil ,
            self.currentSampleTime != nil
        else {
            return self.isRecording
        }
        // 開始寫入
        self.assetWriter?.startWriting()
        self.assetWriter?.startSession(atSourceTime: self.currentSampleTime!)
        self.isRecording = true
        return self.isRecording
    }
    /// 是否暫停錄影
    public func pauseRecord() -> Bool{
        self.isPaused = !self.isPaused
        return self.isPaused
    }
    /// 停止錄影
    ///
    /// - Parameter completion: 會傳送是否正在錄影 與 錄影完成後的暫存 url
    public func finishRecord(completion:@escaping (_ recording:Bool , _ url : URL?)->Void){
        if !self.isRecording {
            completion(self.isRecording , nil)
            return
        }
        self.isRecording = false
        self.assetWriterPixelBufferInput = nil
        self.assetWriter?.finishWriting(completionHandler: { () -> Void in
            DispatchQueue.main.async {
                print("錄影完成")
                completion(self.isRecording , self.movieUrl())
            }
        })
    }
    
    
    /// 設定 filter
    public func setFilter(with index : Int){
        let filterName = self.filters[index]
        self.filter = CIFilter(name: filterName)
    }
    /// 更換相機鏡頭
    public func switchPosition(){
        guard let cameraInput = self.cameraDeviceInput ,
            self.session.inputs.contains(cameraInput),
            self.session.isRunning,
            self.capturePrepare
        else {
            return
        }
        self.session.removeInput(cameraInput)
        switch self.cameraPosition {
        case .front:
            self.cameraPosition = .back
            self.cameraDevice = AVCaptureDevice.default(self.backCameraType, for: AVMediaType.video, position: self.cameraPosition)
            break
        case .back:
            self.cameraPosition = .front
            self.cameraDevice = AVCaptureDevice.default(self.frontCameraType, for: AVMediaType.video, position: self.cameraPosition)
            break
        default:
            break
        }
        let input = try! AVCaptureDeviceInput(device: self.cameraDevice!)
        if self.session.canAddInput(input){
            session.addInput(input)
            self.cameraDeviceInput = input
        }
        self.session.commitConfiguration()
        
    }
    /// 將影片存到相簿中
    public func savedVideoInPhotoLibrary(){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.movieUrl())
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                DispatchQueue.main.async {
                    UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    
    //MARK:- Private Function
    /// 建立 AVAssetWriter
    private func createWriter(){
        // 要先 執行暫存檔案建立 才會取的 緩存的 Pool
        self.checkForAndDeleteFile()
        do {
            assetWriter = try AVAssetWriter(outputURL: movieUrl(), fileType: AVFileType.mov)
        } catch  {
            NSLog("assetWriter build error : \(error.localizedDescription)")
        }
        // 設定 Video Input
        // 影片的壓縮比特律
        let videoCompressionPropertys = [AVVideoAverageBitRateKey : 1280.0 * 1024.0]
        // 影片的輸入設定
        let outputSettings : [String : Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : Int(currentVideoDimensions!.width),
            AVVideoHeightKey : Int(currentVideoDimensions!.height)
            ,AVVideoCompressionPropertiesKey : videoCompressionPropertys // 將影片壓縮
        ]
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        
        // 輸入的影像會先被轉 -90 度
        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        // 現在使用單獨的 kCFBooleanTrue 會回傳 CFBoolean
        let cfTrue : CFBoolean = kCFBooleanTrue
        // 將圖片轉成影片的 buffer 設定
        let sourcePixelBufferAttributesDictionary : [String : Any] = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCMPixelFormat_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
            String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height),
            String(kCVPixelFormatOpenGLESCompatibility) : cfTrue
        ]
        // 將 圖片 Buffer 轉成 影片
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        if assetWriter!.canAdd(assetWriterVideoInput){
            assetWriter!.add(assetWriterVideoInput)
        }else{
            NSLog("assetWriter 無法加入 input ")
        }
        // 聲音輸入設定
        // 準備輸入到 AssetWriter 中的 audio Writer
        let audioSettings : [String:Any] = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 2, // 設定錄製聲音是單通道還是雙通道
            AVSampleRateKey : 44100.0, // 採樣的比率
            AVEncoderBitRateKey: 192000] // 編碼的比率
        // 新增 聲音輸入
        self.audioWritter = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
        self.audioWritter?.expectsMediaDataInRealTime = true
        if assetWriter!.canAdd(audioWritter!) {
            assetWriter!.add(audioWritter!)
        }
    }
    /// 建立暫存 url 以及
    private func checkForAndDeleteFile() {
        let fm = FileManager.default
        let url = movieUrl()
        let exist = fm.fileExists(atPath: url.path)
        if exist {
            print("刪除臨時檔案")
            do {
                try fm.removeItem(at: url as URL)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    /// 暫存的 url
    private func movieUrl() -> URL{
        let tempDir = NSTemporaryDirectory()
        let url = URL(fileURLWithPath: tempDir).appendingPathComponent("video.mov")
        return url
    }
    
}


extension CameRecoder : AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureAudioDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        /// 將 Buffer 轉成 Frame
        /// - Parameters:
        ///   - buffer: 要轉換成 Video 的 buffer
        ///   - formatDescription: Buffer 的簡單描述
        func changeBufferToFrame(with buffer : CMSampleBuffer , formatDescription : CMFormatDescription){
            guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else{
                print("imageBuffer is nil")
                return
            }
            // 回傳 Buffer 的尺寸
            self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            // 要被加入的時間點
            self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(buffer)
            // 要被加入或顯示的圖片
            var outputImage = CIImage(cvImageBuffer: imageBuffer)
            // 判斷是否為前景，把 image 鏡射處理
            if self.cameraPosition == .front ,
                let transformImg = self.coreImgHorizationFlip(With: outputImage){
                outputImage = transformImg
            }
            // 做影像濾鏡
            if let filter = self.filter {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage!
            }
            // 是否開始錄製，寫入的 buffer是否可以被寫入MediaData，pixelBufferPool 是否為 nil
            if self.isRecording &&
                !self.isPaused &&
                self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true ,
                let pool = self.assetWriterPixelBufferInput?.pixelBufferPool {
                
                var newPixelBuffer : CVPixelBuffer? = nil
                // 設定要輸出的 buffer，以及要緩存的 pool
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &newPixelBuffer)
                // 把 image CIImage 轉成 Buffer
                self.context.render(outputImage, to: newPixelBuffer!, bounds: outputImage.extent, colorSpace: nil)
                // 將 新的Buffer 以及建立的時間 寫入 assetWriterPixelBufferInput，並取得是否寫入成功
                if let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: self.currentSampleTime!) ,
                    !success
                {
                    NSLog("Pixel Buffer没有附加成功")
                }
            }
            
            // 若有做轉向 在執行下面 Code
            //            var angle : CGFloat = 0
            //            switch UIDevice.current.orientation{
            //            case .portrait :
            //                angle = -CGFloat.pi/2.0
            //                break
            //            case .landscapeLeft :
            //                angle = -CGFloat.pi/2.0
            //                break
            //            case .landscapeRight:
            //                angle = -CGFloat.pi
            //                break
            //            default:
            //                break
            //            }
            
            let angle : CGFloat = -CGFloat.pi/2
            let transform = CGAffineTransform(rotationAngle: angle)
            outputImage = outputImage.transformed(by: transform)
            
            if let cgImg = self.context.createCGImage(outputImage, from: outputImage.extent){
                DispatchQueue.main.async {
                    self.previewLayer.contents = cgImg
                }
            }
        }
        
        // Memory 會持續循環釋放的一個Memory pool
        autoreleasepool {
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            // 根據 Connection 的 port type 進行處理
            for port in connection.inputPorts{
                switch port.mediaType{
                case AVMediaType.video:
                    changeBufferToFrame(with:sampleBuffer, formatDescription: formatDescription)
                    break
                case AVMediaType.audio :
                    if self.isRecording &&
                        !self.isPaused &&
                        self.audioWritter?.isReadyForMoreMediaData == true {
                        self.audioWritter!.append(sampleBuffer)
                        return
                    }
                    break
                default :
                    break
                }
            }
        }
    }
    /// 將 CIImage 做鏡射
    private func coreImgHorizationFlip(With img : CIImage)->CIImage?{
        var returnImg : CIImage!
        let imgFrame = img.extent
        // outputImage左右鏡射
        returnImg = img.transformed(by: CGAffineTransform(scaleX: 1, y: -1))
        var graphImg = UIImage(ciImage: returnImg)
        // 開啟做圖空間
        UIGraphicsBeginImageContextWithOptions(imgFrame.size, false, 1.0)
        graphImg.draw(in: imgFrame)
        graphImg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        // 把 cgImage 轉成 CIImage
        guard let cgImg = graphImg.cgImage else {
            return nil
        }
        returnImg = CIImage(cgImage: cgImg)
        return returnImg
    }
    
}
extension CameRecoder : AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        NSLog("完成錄影")
    }
    
    
}
extension CameRecoder : AVCaptureMetadataOutputObjectsDelegate {
}

