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
    let recorder = CameRecoder.sharedInstance
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
            recordSoundButton.backgroundColor = .white
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recorder.prepareVideoCam(with: self.view){_ in
            
        }

        self.filterScrollView.delegate = self
        // 隱藏水平與垂直的線
        self.filterScrollView.showsVerticalScrollIndicator = false
        self.filterScrollView.showsHorizontalScrollIndicator = false
        self.addFiltersButton()
        
        // 放大縮小畫面手勢
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(FilterCameraViewController.roomingFrame(_:)))
        self.view.addGestureRecognizer(pinchGesture)
        
        self.leftSpace = self.filterScrollView.frame.width
        
        //設定錄音 Image
        let soundImg = self.recordSound ? self.recordSoundImage : self.recordStopSoundImage
        self.recordSoundButton.setImage(soundImg, for: UIControlState.normal)
        // 設定暫停 Button
        self.pauseButton.setImage(self.pauseImage, for: UIControlState.normal)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recorder.startCaptureFrame()
        self.scrollLeftConstraint.constant = self.leftSpace
        /// 將 Button 變回原本的大小比例
        self.recordButton.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        /// 停止抓取畫面
        recorder.stopCaptureFrame()
    }
    //MARK: - Action Function
    @IBAction func recoderVideo(_ sender: UIButton) {
        if self.recording {
            recorder.finishRecord { (recording, fileUrl) in
                self.recording = recording
                UIView.animate(withDuration: 0.5, animations: {
                    sender.transform = CGAffineTransform(scaleX: 1, y: 1)
                    // 移除所有的動畫
                    sender.layer.removeAllAnimations()
                    // 將 Pause Button 變回暫停圖示
                    self.pauseButton.setImage(self.pauseImage, for: .normal)
                    // 暫存的 URL
                    if let url = fileUrl{
                        self.presentVideoPlayer(with: url)
                    }
                })
            }
        }else{
            self.recording = recorder.startRecord()
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [.repeat , .autoreverse , .allowUserInteraction], animations: {
                sender.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            })
        }
        // 當開始錄製時，隱藏換鏡頭與錄製聲音的功能
        self.recordSoundButton.isHidden = self.recording
        self.changePositionButton.isHidden = self.recording
    }
    @IBAction func switchPosition(_ sender: UIButton) {
        self.recorder.switchPosition()
    }
    
    @IBAction func pauseRecording(_ sender: UIButton) {
        if recorder.pauseRecord() {
            sender.setImage(self.startImage, for: .normal)
        }else{
            sender.setImage(self.pauseImage, for: UIControlState.normal)
        }
    }
    // 顯示 filters 濾鏡們
    @IBAction func showFilters(_ sender : UIButton){
        // 顯示或隱藏 filters
        UIView.animate(withDuration: 0.5) {
            self.scrollLeftConstraint.constant = self.scrollLeftConstraint.constant == 0.0 ? self.leftSpace : 0.0
            self.view.layoutIfNeeded()
        }
    }
    /// 錄製聲音
    @IBAction func recordSound(_ sender: UIButton) {
        self.recordSound = !self.recordSound
        let soundImg = self.recordSound ? self.recordSoundImage : self.recordStopSoundImage
        self.recordSoundButton.setImage(soundImg, for: UIControlState.normal)
        self.recorder.recordAudio(with: self.recordSound)
    }
    
    
    //MARK: - Private Function
    /// 新增 filter Button
    func addFiltersButton(){
        let width : CGFloat = self.filterScrollView.frame.width
        print("filterScrollView with : \(width)")
        print("filterButton With :\(self.filterButton.frame.width)")
        var filterButtons : [UIButton] = [UIButton]()
        for index in 0..<recorder.filters.count{
            let title = recorder.filters[index].count == 0 ? "None" : recorder.filters[index]
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            
            self.filterScrollView.addSubview(button)
            filterButtons.append(button)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.bottomAnchor.constraint(equalTo: self.recordButton.topAnchor, constant:
                -20).isActive = true
            if index == 0{
                button.leftAnchor.constraint(equalTo: self.filterScrollView.leftAnchor, constant: 5.0).isActive = true
            }else{
                button.leftAnchor.constraint(equalTo: filterButtons[index-1].rightAnchor, constant: 5).isActive = true
            }
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            button.widthAnchor.constraint(equalToConstant: width-5).isActive = true
            
            button.addTarget( self, action: #selector(FilterCameraViewController.changeFilter(_:)), for: UIControlEvents.touchUpInside)
            button.backgroundColor = UIColor.green
        }
        var maxWidth : CGFloat = 0
        maxWidth = CGFloat(filterButtons.count) * width
        self.filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: maxWidth)
        self.filterScrollView.isPagingEnabled = true
        self.filterScrollView.layoutSubviews()
    }
    /// 顯示播放的 VC
    private func presentVideoPlayer(with url :URL){
        let playerVC = UIStoryboard(name: "VideoPlayer", bundle: Bundle(for: FilterCameraViewController.self)).instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
        playerVC.player = AVPlayer(url: url)
        DispatchQueue.main.async {
            self.present(playerVC
                , animated: true, completion: nil)
        }
        
    }
    
    
    
    @objc func changeFilter(_ sender : UIButton){
        recorder.setFilter(with: sender.tag)
    }
    @objc func roomingFrame(_ sender : UIPinchGestureRecognizer){
        switch sender.state {
        case .changed:
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
        recorder.setFilter(with:index)
    }
}

