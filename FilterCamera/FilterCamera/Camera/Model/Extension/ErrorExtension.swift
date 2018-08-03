//
//  ErrorExtension.swift
//  FilterCamera
//
//  Created by Uran on 2018/7/16.
//  Copyright © 2018年 Uran. All rights reserved.
//

import Foundation
import UIKit

/// Camera 會遇到的錯誤
enum CameraError : Swift.Error {
    case captureSessionNotAlreadyRunning(message : String)
    case captureSessionIsMissing(message : String)
    case inputsAreInvalid(message : String)
    case invalidOperation(message : String)
    case noCamerasAvailable(message : String)
    case unknown(message : String)
}
extension CameraError : LocalizedError{
    public var errorDescription: String? {
        switch self {
        case .captureSessionNotAlreadyRunning(message : let message):
            return "Session 尚未準備好 : \(message)"
        case .captureSessionIsMissing(message : let message):
            return "Session 錯誤：\(message)"
        case .inputsAreInvalid(message : let message):
            return "輸入皆為浮雲 : \(message)"
        case .invalidOperation(message : let message):
            return "無效選擇 \(message)"
        case .noCamerasAvailable(message : let message):
            return "No available Camera : \(message)"
        case .unknown(message: let message):
            return message
        }
    }
}

extension NSError {
    convenience init(errorString : String) {
        self.init(domain: errorString, code: 8591, userInfo: nil)
    }
}
