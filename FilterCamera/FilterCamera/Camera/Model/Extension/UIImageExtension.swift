//
//  UIImageExtension.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/12.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit
import Photos

extension UIImage {
    
    /// 將圖片進行轉向
    ///
    /// - Parameter radians: 轉向的角度
    func rotate(radians: Double) -> UIImage {
        let angals : CGFloat = CGFloat(radians)
        
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: angals)).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: angals)
        
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    /// 將圖片進行轉向
    ///
    /// - Parameter radians: 轉向的角度
    func rotate(radians: Float) -> UIImage {
        let angals : CGFloat = CGFloat(radians)

        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: angals)).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: angals)
        
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// 將圖片進行轉向
    ///
    /// - Parameter radians: 轉向的角度
    func rotate(radians: CGFloat) -> UIImage {
        let angal : CGFloat = radians
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: angal)).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: angal)
        
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// 圖片轉向
    func orientationFlip(orientation : UIImageOrientation)->UIImage{
        var flipImage : UIImage!
        if self.cgImage != nil {
            flipImage = UIImage(cgImage: self.cgImage!, scale: self.scale, orientation: orientation)
        }else if self.ciImage != nil{
            flipImage = UIImage(ciImage: self.ciImage!, scale: self.scale, orientation: orientation)
        }else{
            print("the horizontalFlip is nil")
        }
        
        return flipImage
    }
    /// 將圖片存到相簿
    func savedInPhotoLibrary(){
        // 去詢問權限
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized :
                NSLog("允許")
                // 儲存照片到相簿中
                do {
                    try PHPhotoLibrary.shared().performChangesAndWait {
                        PHAssetChangeRequest.creationRequestForAsset(from: self)
                    }
                }catch {
                    print("save image fail :\(error.localizedDescription)")
                }
                break
            case .notDetermined :
                NSLog("未決定")
                break
            case .denied:
                NSLog("拒絕")
                break
            case .restricted :
                NSLog("有限制")
                break
            }
        }
    }
}
