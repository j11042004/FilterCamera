//
//  FloatExtension.swift
//  FilterCamera
//
//  Created by Uran on 2018/8/17.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit

extension Float {
    /// 將秒換算成 日 時 秒 分
    func changeTime()->String{
        let totalSec = Int(self)
        let day = Int(totalSec/(24*60*60))
        let hour = totalSec/(60*60) - day*24
        let minute = totalSec/60 - day*24*60 - hour*60
        let sec = totalSec - day*24*60*60 - hour*60*60 - minute*60
        
        var timeText = ""
        let dayText = day >= 10 ? "\(day)" : "0\(day)"
        let hourText = hour >= 10 ? "\(hour)" : "0\(hour)"
        let minText = minute >= 10 ? "\(minute)" : "0\(minute)"
        let secText = sec >= 10 ? "\(sec)" : "0\(sec)"
        
        if day != 0 {
            timeText.append("\(dayText):\(hourText):\(minText):\(secText)")
            return timeText
        }else if hour != 0{
            timeText.append("\(hourText):\(minText):\(secText)")
            return timeText
        }else {
            timeText.append("\(minText):\(secText)")
            return timeText
        }
    }
}
