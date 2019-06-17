//
//  UrlExtension.swift
//  FilterCamera
//
//  Created by Uran on 2018/8/6.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import Photos

extension URL{
    /// 將 相片或影片網址 存到 相簿 中
    func savePhotoUrlInLubrary(completion:@escaping (Bool , Error?) -> Void){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self)
        }) { saved, error in
            completion(saved,error)
        }
    }
}
