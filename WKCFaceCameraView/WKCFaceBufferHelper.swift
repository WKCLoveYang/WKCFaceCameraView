//
//  WKCCoolHelper.swift
//  SwiftFuck
//
//  Created by wkcloveYang on 2020/7/23.
//  Copyright © 2020 wkcloveYang. All rights reserved.
//

import UIKit

public class WKCFaceBufferHelper: NSObject {
    
    public static func image(buffer: CVPixelBuffer) -> UIImage? {
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        let ciimage = CIImage(cvPixelBuffer: buffer)
        let temporaryContext = CIContext(options: nil)
        let videoImage = temporaryContext.createCGImage(ciimage, from: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        guard let vimg = videoImage else { return nil }
        let image = UIImage(cgImage: vimg)
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return image
    }

}
