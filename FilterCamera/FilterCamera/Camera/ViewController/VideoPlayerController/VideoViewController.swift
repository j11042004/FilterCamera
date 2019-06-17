//
//  VideoViewController.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/26.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
class VideoViewController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if let avUrlAsset = self.player?.currentItem?.asset  as? AVURLAsset {
            let storedUrl = avUrlAsset.url
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
