//
//  WKCFaceImageCropper.swift
//  SwiftFuck
//
//  Created by wkcloveYang on 2020/7/20.
//  Copyright © 2020 wkcloveYang. All rights reserved.
//

import UIKit
import Vision

extension UIImage {
    /// 裁剪
    /// - Parameter rect: newRect
    /// - Returns: 裁剪后的图片
    @objc public func cropped(at rect: CGRect) -> UIImage {
        let origin: CGPoint = CGPoint(x: -rect.origin.x, y: -rect.origin.y)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        self.draw(at: origin)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img!
    }
    
    public var resizedImage: UIImage {
        let maxValue = max(self.size.width, self.size.height)
        let limitValue: CGFloat = 1024
        if maxValue >= limitValue {
            if self.size.width > self.size.height {
                return self.resizeImage(image: self, size: CGSize(width: limitValue, height: limitValue * self.size.height / self.size.width))!
            }
            
            return self.resizeImage(image: self, size: CGSize(width: limitValue * self.size.width / self.size.height, height: limitValue))!
        }
        
        return self
    }
    
    private func resizeImage(image: UIImage, size: CGSize) -> UIImage? {
        var actualHeight = image.size.height
        var actualWidth = image.size.width
        
        var oldRatio = actualWidth / actualHeight
        let newRatio = size.width / size.height
        
        if (oldRatio < newRatio) {
            oldRatio = size.height / actualHeight;
            actualWidth = oldRatio * actualWidth;
            actualHeight = size.height;
        }
        else {
            oldRatio = size.width / actualWidth;
            actualHeight = oldRatio * actualHeight;
            actualWidth = size.width;
        }
        
        let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return result
    }
}

@objc public class WKCFaceImageCropper: NSObject {
    
    /// 单例
   @objc public static let shared: WKCFaceImageCropper = WKCFaceImageCropper()
    
    /// 按人脸位置及所需比例裁剪图片
    /// 注: 无人脸只会按比例裁剪
    /// - Parameters:
    ///   - image: 原图
    ///   - heightWidthScale: 高 / 宽
    ///   - completion: 回调
    @objc public func cropFaceImage(image: UIImage,
                                    heightWidthScale: CGFloat = 1.0,
                                    completion:@escaping ((UIImage) -> ())) {

        DispatchQueue.global().async {
            self.innerDetectFaces(image: image.resizedImage,
                                  heightWidthScale: heightWidthScale) { (resultImg) in
                                    DispatchQueue.main.async {
                                        completion(resultImg)
                                    }
            }
        }
    }
    
    private func innerDetectFaces(image: UIImage,
                                  heightWidthScale: CGFloat,
                                  completion:@escaping ((UIImage) -> ())) {
        let ciimage = CIImage(image: image)
        guard let ciimg = ciimage else {
            completion(self.nofaceCropedImage(image: image, heightWidthScale: heightWidthScale))
            return
        }

        let requestHandle = VNImageRequestHandler(ciImage: ciimg, options: [VNImageOption: Any]())
        let faceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if let _ = error {
                completion(self.nofaceCropedImage(image: image, heightWidthScale: heightWidthScale))
                return
            }

            let observations = request.results
            guard let obs = observations else {
                completion(self.nofaceCropedImage(image: image, heightWidthScale: heightWidthScale))
                return
            }

            let faceObservation: VNFaceObservation? = obs.first as? VNFaceObservation
            guard let faceObs = faceObservation else {
                completion(self.nofaceCropedImage(image: image, heightWidthScale: heightWidthScale))
                return
            }

            completion(self.faceCropedImage(image: image, face: faceObs, heightWidthScale: heightWidthScale))
        }

       try? requestHandle.perform([faceRequest])
    }


    private func faceCropedImage(image: UIImage,
                                 face: VNFaceObservation,
                                 heightWidthScale: CGFloat) -> UIImage {
        let rect = face.boundingBox
        let faceRect = self.transformFaceRectInImage(rect: rect, image: image)
        let shouldCropRect = self.shouldCropFaceRect(faceRect: faceRect, image: image, heightWidthScale: heightWidthScale)
        return image.cropped(at: shouldCropRect)
    }
    
    private func shouldCropFaceRect(faceRect: CGRect,
                                    image: UIImage,
                                    heightWidthScale: CGFloat) -> CGRect {
        var cropX: CGFloat = 0
        var cropY: CGFloat = 0
        var cropWidth: CGFloat = 0
        var cropHeight: CGFloat = 0

        if image.size.height / image.size.width > heightWidthScale {
            if faceRect.origin.x < 0 {
                cropX = 0
                cropWidth = image.size.width
            } else {
               let minValue = min(faceRect.origin.x, image.size.width - faceRect.origin.x - faceRect.width)
                cropWidth = faceRect.width + minValue * 2.0
                if faceRect.origin.x < (image.size.width - faceRect.origin.x - faceRect.width) {
                    cropX = 0
                } else {
                    cropX = image.size.width - cropWidth
                }
            }

            cropHeight = cropWidth * heightWidthScale
            cropY = faceRect.midY - cropHeight / 2.0

            if cropY < 0 {
                cropY = 0
            }
        } else {
            if faceRect.origin.y < 0 {
                cropY = 0
                cropHeight = image.size.height
            } else {
                let minValue = min(faceRect.origin.y, image.size.height - faceRect.origin.y - faceRect.height)
                cropHeight = faceRect.height + minValue * 2.0

                if faceRect.origin.y < (image.size.height - faceRect.origin.y - faceRect.height) {
                    cropY = 0
                } else {
                    cropY = image.size.height - cropHeight
                }
            }

            cropWidth = cropHeight / heightWidthScale
            cropX = faceRect.midX - cropWidth / 2.0

            if cropX < 0 {
                cropX = 0
            }
        }

        return CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
    }
    
    private func nofaceCropedImage(image: UIImage,
                                   heightWidthScale: CGFloat) -> UIImage {
        var x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0
        
        if image.size.height / image.size.width > heightWidthScale {
            width = image.size.width
            height = width * heightWidthScale
            y = (image.size.height - height) / 2.0
        } else {
            height = image.size.height
            width = height / heightWidthScale
            y = (image.size.width - width) / 2.0
        }
        
        return image.cropped(at: CGRect(x: x, y: y, width: width, height: height))
    }
    
    
    private func transformFaceRectInImage(rect: CGRect, image: UIImage) -> CGRect {
        let x: CGFloat = rect.origin.x * image.size.width
        let width: CGFloat = rect.size.width * image.size.width
        let height: CGFloat = rect.size.height * image.size.height
        let y: CGFloat = image.size.height - rect.origin.y * image.size.height - height

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
