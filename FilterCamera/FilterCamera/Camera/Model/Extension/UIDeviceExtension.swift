//
//  UIDeviceExtension.swift
//  ImagePickerManager
//
//  Created by Uran on 2018/7/9.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit
//MARK: - UIDevice延展
public extension UIDevice {
    enum iType {
        case iPodTouch1
        case iPodTouch2
        case iPodTouch3
        case iPodTouch4
        case iPodTouch5Gen
        case iPodTouch6
        case iPhone4
        case iPhone4s
        case iPhone5
        case iPhone5c
        case iPhone5s
        case iPhone6
        case iPhone6Plus
        case iPhone6s
        case iPhone6sPlus
        case iPhoneSE
        case iPhone7
        case iPhone7Plus
        case iPhone8
        case iPhone8Plus
        case iPhoneX
        case iPad
        case iPad3G
        case iPad2
        case iPadMini
        case iPad3
        case iPad4
        case iPadAir
        case iPadMini2
        case iPadMini3
        case iPadMini4
        case iPadAir2
        case iPadPro97
        case iPadPro129
        case AppleTV2
        case AppleTV3
        case AppleTV4
        case Simulator
    }
    /// iPhone 型號
    var modelName: iType {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 ,
                value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod1,1":  return .iPodTouch1
        case "iPod2,1":  return .iPodTouch2
        case "iPod3,1":  return .iPodTouch3
        case "iPod4,1":  return .iPodTouch4
        case "iPod5,1":  return .iPodTouch5Gen
        case "iPod7,1":   return .iPodTouch6
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":  return .iPhone4
        case "iPhone4,1":  return .iPhone4s
        case "iPhone5,1":   return .iPhone5
        case  "iPhone5,2":  return .iPhone5
        case "iPhone5,3":  return .iPhone5c
        case "iPhone5,4":  return .iPhone5c
        case "iPhone6,1":  return .iPhone5s
        case "iPhone6,2":  return .iPhone5s
        case "iPhone7,2":  return .iPhone6
        case "iPhone7,1":  return .iPhone6Plus
        case "iPhone8,1":  return .iPhone6s
        case "iPhone8,2":  return .iPhone6sPlus
        case "iPhone8,4":  return .iPhoneSE
        case "iPhone9,1":  return .iPhone7
        case "iPhone9,2":  return .iPhone7Plus
        case "iPhone9,3":  return .iPhone7
        case "iPhone9,4":  return .iPhone7Plus
        case "iPhone10,1","iPhone10,4":   return .iPhone8
        case "iPhone10,2","iPhone10,5":   return .iPhone8Plus
        case "iPhone10,3","iPhone10,6":   return .iPhoneX
            
        case "iPad1,1":   return .iPad
        case "iPad1,2":   return .iPad3G
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":   return .iPad2
        case "iPad2,5", "iPad2,6", "iPad2,7":  return .iPadMini
        case "iPad3,1", "iPad3,2", "iPad3,3":  return .iPad3
        case "iPad3,4", "iPad3,5", "iPad3,6":  return .iPad4
        case "iPad4,1", "iPad4,2", "iPad4,3":  return .iPadAir
        case "iPad4,4", "iPad4,5", "iPad4,6":  return .iPadMini2
        case "iPad4,7", "iPad4,8", "iPad4,9":  return .iPadMini3
        case "iPad5,1", "iPad5,2":  return .iPadMini4
        case "iPad5,3", "iPad5,4":  return .iPadAir2
        case "iPad6,3", "iPad6,4":  return .iPadPro97
        case "iPad6,7", "iPad6,8":  return .iPadPro129
        case "AppleTV2,1":  return .AppleTV2
        case "AppleTV3,1","AppleTV3,2":  return .AppleTV3
        case "AppleTV5,3":   return .AppleTV4
        case "i386", "x86_64":   return .Simulator
        default:  return .Simulator
        }
    }
}
