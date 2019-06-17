//
//  PlayerViewController.swift
//  FilterCamera
//
//  Created by Uran on 2018/8/6.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import AVFoundation
enum PlayerStatus {
    case None
    case End
    case Play
    case Pause
}

class PlayerViewController: UIViewController {
    var videoUrl : URL?
    var playItem : AVPlayerItem?
    var player : AVPlayer?
    var playerLayer : AVPlayerLayer?
    var playStatus : PlayerStatus = .None
    
    let playerCallTime : CMTime = CMTime(value: 1, timescale: 10)
    var fps : Float = 0
    var totalSec : Float = 0
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var durationSlider: UISlider!
    
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var passTimeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 當播放結束時，會收到通知
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.playStatus = .End
            self.saveVideoAlert()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func playVideo(_ sender: UIButton) {
        switch self.playStatus {
        case .Play:
            self.player?.pause()
            self.playStatus = .Pause
            break
        case .None:
            self.playVideo()
            self.playStatus = .Play
            break
        case .Pause:
            self.player?.play()
            self.playStatus = .Play
            break
        case .End:
            self.playVideo()
            self.playStatus = .Play
            break
        }
    }
    
    
    @IBAction func touchDuration(_ sender: UISlider) {
        self.player?.pause()
        self.playStatus = .Pause
    }
    /// 移動行動條
    @IBAction func moveDuration(_ sender: UISlider) {
        guard self.playItem != nil ,
            self.player != nil ,
            sender.maximumValue != 0
        else {
            NSLog("can't jump")
            return
        }
        let seconds : Int64 = Int64(sender.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        print("changeTime : \(targetTime)")
        //播放器播放到目的的秒數
        player?.seek(to: targetTime)
    }
    @IBAction func leaveDuration(_ sender: UISlider) {
        self.player?.play()
        self.playStatus = .Play
    }
    
    
}
extension PlayerViewController{
    /// 播放影片
    func playVideo(){
        guard let url = videoUrl else {
            NSLog("目的 Url 是 nil")
            return
        } 
        self.playItem = AVPlayerItem(url: url)
        // 取的影片總時間
        let duration = self.playItem!.asset.duration
        totalSec = Float(CMTimeGetSeconds(duration))
        self.totalTimeLabel.text = totalSec.changeTime()
        if let itemFps = playItem?.asset.tracks(withMediaType: AVMediaType.video).first?.nominalFrameRate{
            fps = itemFps
        }
        
        // 決定 Slider 時間的最大值
        self.durationSlider.maximumValue = totalSec
        self.durationSlider.isContinuous = false
        // 設定 Player
        self.player = AVPlayer(playerItem: playItem)
        // 每隔設定的時間調動一次
        self.player?.addPeriodicTimeObserver(forInterval: playerCallTime, queue: DispatchQueue.main, using: { (time) in
            let currentTime = CMTimeGetSeconds(self.player!.currentTime())
            // 更換 Slider
            UIView.animate(withDuration: 1, animations: {
                let nowTime = Float(currentTime)
                self.durationSlider.value = nowTime
                self.passTimeLabel.text = nowTime.changeTime()
            })
        })
        
        // 設定要顯示的 Layer
        // 從 SuperLayer移除
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer?.frame = self.videoView.frame
        self.playerLayer?.videoGravity = .resizeAspect
        self.player?.rate = 1.0
        self.view.layer.addSublayer(self.playerLayer!)
        self.player?.play()
    }
    /// 是否儲存影片 Alert
    func saveVideoAlert(){
        let alert = UIAlertController(title: nil, message: "是否要儲存影片", preferredStyle: .alert)
        let save = UIAlertAction(title: "儲存", style: UIAlertAction.Style.default, handler: { (action) in
            self.videoUrl?.savePhotoUrlInLubrary(completion: { (success, error) in
                if let error = error{
                    NSLog("saved Error : \(error.localizedDescription)")
                    return
                }
                NSLog("儲存%@!", success ? "成功" : "失敗")
            })
        })
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(save)
        alert.addAction(cancel)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

