//
//  FilterCameraViewController.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/19.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreImage
class FilterCameraViewController: UIViewController {
    /// 錄影 Manager
    let recoder = CameRecoder()
    /// 錄影按鈕
    @IBOutlet weak var recordButton: UIButton!{
        didSet {
            recordButton.backgroundColor = UIColor.red
            recordButton.clipToCircleShape()
        }
    }
    /// 是否錄製聲音 Button
    @IBOutlet weak var recordSoundButton: UIButton!{
        didSet{
            recordSoundButton.clipToCircleShape()
        }
    }
    /// 更換鏡頭 Button
    @IBOutlet weak var changePositionButton: UIButton!
    /// 暫停按鈕
    @IBOutlet weak var pauseButton: UIButton!
    /// 濾鏡按鈕
    @IBOutlet weak var filterButton: UIButton!
    /// 濾鏡選擇的ScrollView
    @IBOutlet weak var filterScrollView: UIScrollView!
    /// Filter ScrollView 的 Constraint
    @IBOutlet weak var scrollLeftConstraint: NSLayoutConstraint!
    /// Filter ScrollView 寬度
    var leftSpace : CGFloat = 0
    /// 全部濾鏡的按鈕
    var filterButtons : [UIButton] = [UIButton]()
    /// 是否錄影
    var recording : Bool = false
    /// 是否錄製聲音
    var recordSound : Bool = true
    /// 錄音 Image
    let recordSoundImage = UIImage(named: "sound.png")
    /// 停止錄音 Image
    let recordStopSoundImage = UIImage(named: "soundStop.png")
    /// 暫停 Image
    let pauseImage = UIImage(named: "pause.png")
    /// 錄影 Image
    let startImage = UIImage(named: "start.png")
    /// 上次縮放的距離
    var preScale : CGFloat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 準備錄影機
        recoder.prepareVideoCam(with: self.view){_ in
            
        }
        self.filterScrollView.delegate = self
        // 隱藏水平與垂直的線
        self.filterScrollView.showsVerticalScrollIndicator = false
        self.filterScrollView.showsHorizontalScrollIndicator = false
        self.setFilterViewButton()
        
        // 放大縮小畫面手勢
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(FilterCameraViewController.roomingFrame(_:)))
        self.view.addGestureRecognizer(pinchGesture)
        
        
        //設定錄音 Image
        let soundImg = self.recordSound ? self.recordSoundImage : self.recordStopSoundImage
        self.recordSoundButton.setImage(soundImg, for: UIControl.State.normal)
        // 設定暫停 Button
        self.pauseButton.setImage(self.pauseImage, for: UIControl.State.normal)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reLayoutFilterViewSubItem()
        // 設定 Scroll View 距離罪左邊的 Constraint
        self.scrollLeftConstraint.constant = self.leftSpace
        self.filterScrollView.contentOffset = CGPoint(x: 0, y: 0)
        self.recoder.setFilter(with: 0)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.recoder.updatePreviewLayer()
        recoder.startCaptureFrame()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.finishRecoder(show: false)
        /// 停止抓取畫面
        recoder.stopCaptureFrame()
    }
    //MARK: - Action Function
    @IBAction func recoderVideo(_ sender: UIButton) {
        if self.recording {
            self.finishRecoder(show: true)
        }else{
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [.repeat , .autoreverse , .allowUserInteraction], animations: {
                sender.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            })
            self.recording = recoder.startRecord()
        }
        // 當開始錄製時，隱藏換鏡頭與錄製聲音的功能
        self.recordSoundButton.isHidden = self.recording
        self.changePositionButton.isHidden = self.recording
    }
    @IBAction func switchPosition(_ sender: UIButton) {
        self.recoder.switchPosition()
    }
    @IBAction func pauseRecording(_ sender: UIButton) {
        if recoder.pauseRecord() {
            sender.setImage(self.startImage, for: .normal)
        }else{
            sender.setImage(self.pauseImage, for: UIControl.State.normal)
        }
    }
    // 顯示 filters 濾鏡選項
    @IBAction func showFilters(_ sender : UIButton){
        // 顯示或隱藏 filters
        UIView.animate(withDuration: 0.5) {
            self.scrollLeftConstraint.constant = self.scrollLeftConstraint.constant == 0.0 ? self.leftSpace : 0.0
            self.view.layoutIfNeeded()
        }
        // 若 開啟後的 ScrollView 比 預設的 LeftSpace 還寬就做更換
        if self.filterScrollView.frame.width > self.leftSpace{
            print("orignal leftspace : \(leftSpace) , will change space : \(self.filterScrollView.frame.width)")
            self.leftSpace = self.filterScrollView.frame.width
            self.reLayoutFilterViewSubItem()
        }
        
    }
    /// 錄製聲音
    @IBAction func recordSound(_ sender: UIButton) {
        self.recordSound = !self.recordSound
        let soundImg = self.recordSound ? self.recordSoundImage : self.recordStopSoundImage
        self.recordSoundButton.setImage(soundImg, for: .normal)
        self.recoder.recordAudio(with: self.recordSound)
    }
    //MARK: - Private Function
    /// 新增 filter Button
    func setFilterViewButton(){
        for index in 0..<recoder.filters.count{
            let title = recoder.filterNames[index]
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            
            self.filterScrollView.addSubview(button)
            self.filterButtons.append(button)
            button.addTarget( self, action: #selector(FilterCameraViewController.changeFilter(_:)), for: .touchUpInside)
            button.backgroundColor = UIColor.green
        }
    }
    /// 重新更新 Filter View 內部的 Button item
    func reLayoutFilterViewSubItem(){
        // 先設定 FilterScrollView 最寬為多少
        self.leftSpace = self.filterScrollView.frame.width > self.leftSpace ? self.filterScrollView.frame.width : self.leftSpace
        // 重新設定每個 Button 的 Constraint
        for index in 0..<self.filterButtons.count{
            let button = self.filterButtons[index]
            button.translatesAutoresizingMaskIntoConstraints = false
            // 移除所有 Constraint
            for constraint in button.constraints{
                button.removeConstraint(constraint)
            }
            button.bottomAnchor.constraint(equalTo: self.recordButton.topAnchor, constant:
                -20).isActive = true
            if index == 0{
                button.leftAnchor.constraint(equalTo: self.filterScrollView.leftAnchor, constant: 5.0).isActive = true
            }else{
                button.leftAnchor.constraint(equalTo: filterButtons[index-1].rightAnchor, constant: 5).isActive = true
            }
            // button 高度 constraint
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            // button 寬度 constraint
            button.widthAnchor.constraint(equalToConstant: self.leftSpace-5).isActive = true
        }
        var maxWidth : CGFloat = 0
        maxWidth = CGFloat(filterButtons.count) * self.leftSpace
        self.filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: maxWidth)
        self.filterScrollView.isPagingEnabled = true
        self.filterScrollView.layoutSubviews()
        
    }
    /// 完成 錄影
    func finishRecoder(show : Bool){
        recoder.finishRecord { (recording, fileUrl) in
            self.recording = recording
            UIView.animate(withDuration: 0.5, animations: {
                self.recordButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                // 移除所有的動畫
                self.recordButton.layer.removeAllAnimations()
                // 將 Pause Button 變回暫停圖示
                self.pauseButton.setImage(self.pauseImage, for: .normal)
                // 暫存的 URL
                if let url = fileUrl , show{
                    self.presentVideoPlayer(with: url)
                }
            })
            // 當開始錄製時，隱藏換鏡頭與錄製聲音的功能
            self.recordSoundButton.isHidden = false
            self.changePositionButton.isHidden = false
        }
        
    }
    /// 顯示播放的 VC
    private func presentVideoPlayer(with url :URL){
        let playerVC = UIStoryboard(name: "VideoPlayer", bundle: Bundle(for: FilterCameraViewController.self)).instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
        playerVC.player = AVPlayer(url: url)
        let playVC = UIStoryboard(name: "VideoPlayer", bundle: Bundle(for: FilterCameraViewController.self)).instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        playVC.videoUrl = url
        DispatchQueue.main.async {
            if self.navigationController != nil{
                self.navigationController?.pushViewController(playVC, animated: true)
            }else{
                self.present(playVC
                    , animated: true, completion: nil)
            }
        }
    }
    /// 更換指定的 filter
    @objc func changeFilter(_ sender : UIButton){
        recoder.setFilter(with: sender.tag)
    }
    /// 畫面放大縮小
    @objc func roomingFrame(_ sender : UIPinchGestureRecognizer){
        NSLog("scale : \(sender.scale)")
        switch sender.state {
        case .cancelled:
            break
        case .ended:
            break
        case .failed:
            break
        default:
            break
        }
    }
}
extension FilterCameraViewController : UIScrollViewDelegate{
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let nowX = scrollView.contentOffset.x
        let floatIndex = nowX / self.filterScrollView.frame.width
        let index = (floatIndex - CGFloat(Int(floatIndex))) >= 0.5 ? Int(floatIndex)+1 : Int(floatIndex)
        recoder.setFilter(with:index)
    }
}
extension FilterCameraViewController : UIGestureRecognizerDelegate{
    
}

