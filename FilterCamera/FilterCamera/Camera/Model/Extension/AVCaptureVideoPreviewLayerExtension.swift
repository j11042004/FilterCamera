//
//  AVCaptureVideoPreviewLayerExtension.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/12.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import AVKit

extension AVCaptureVideoPreviewLayer {
    /// 更換鏡頭選轉的方向
    func transformOrientation() -> Double{
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            self.connection?.videoOrientation = .landscapeLeft
            return Double.pi / 2
        case .landscapeRight:
            self.connection?.videoOrientation = .landscapeRight
            
            return -Double.pi / 2
        default:
            self.connection?.videoOrientation = .portrait
            return 0
        }
    }
}
