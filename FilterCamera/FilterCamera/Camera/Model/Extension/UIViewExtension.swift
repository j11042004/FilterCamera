//
//  UIButtonExtension.swift
//  FilterCamera
//
//  Created by Uran on 2018/8/3.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit
extension UIView{
    /// 轉成圓型
    func clipToCircleShape(){
        if self.frame.width != self.frame.height{
            NSLog("Can't change button's layer to circle Shape，無法把 畫面形狀變為圓形")
            return
        }
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
    }
}
