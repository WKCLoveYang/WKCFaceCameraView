//
//  WKCVisonManager.swift
//  MLKitFace
//
//  Created by wkcloveYang on 2020/9/29.
//  Copyright © 2020 wkcloveYang. All rights reserved.
//

import UIKit
import Vision

let WKCVisionBufferQueue: DispatchQueue = DispatchQueue(label: "com.vision.buffer")

public class WKCVisonManager: NSObject {
    
    public static let shared = WKCVisonManager()
    
    public enum ErrorCode: Int {
        case none = 0
        case imageEmpty = 1
        case noface = 2
    }
    
    public func detectFaces(image: UIImage,
                            completion: ((Bool) -> ())?) {
        DispatchQueue.global().async {
            let ciimage = CIImage(image: image)
            guard let cImage = ciimage else {
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            let requestHandle = VNImageRequestHandler(ciImage: cImage, options: [:])
            let request = VNDetectFaceLandmarksRequest { (request, error) in
                let observations: [VNFaceObservation]? = request.results as? [VNFaceObservation]
                if let theObservations = observations {
                    DispatchQueue.main.async {
                        completion?(self.hasDetectFace(observation: theObservations))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(false)
                    }
                }
            }
            try? requestHandle.perform([request])
        }
    }
    
    public func detectFaces(buffer: CVPixelBuffer,
                            completion: ((Bool) -> ())?) {
        WKCVisionBufferQueue.async {
            let requestHandle = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
            let request = VNDetectFaceLandmarksRequest { (request, error) in
                let observations: [VNFaceObservation]? = request.results as? [VNFaceObservation]
                if let theObservations = observations {
                    DispatchQueue.main.async {
                        completion?(self.hasDetectFace(observation: theObservations))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(false)
                    }
                }
            }
            try? requestHandle.perform([request])
        }
    }
    
    
    
    fileprivate func hasDetectFace(observation: [VNFaceObservation]) -> Bool {
        return observation.first {
            faceIn(landmark: $0.landmarks)
        } != nil
    }
    
    private func faceIn(landmark: VNFaceLandmarks2D?) -> Bool {
        var hasFace: Bool = false
        
        if let _ = landmark?.leftEye, let _ = landmark?.leftEyebrow, let _ = landmark?.rightEye, let _ = landmark?.rightEyebrow, let _ = landmark?.leftPupil, let _ = landmark?.rightPupil, let _ = landmark?.nose, let _ = landmark?.noseCrest, let _ = landmark?.faceContour, let _ = landmark?.medianLine, let _ = landmark?.outerLips, let _ = landmark?.innerLips {
            hasFace = true
        
        }
        
        return hasFace
    }
    
    
    public func detectFaces(image: UIImage,
                            completion: (([WKCVisonModel]?, ErrorCode) -> ())?) {
        DispatchQueue.global().async {
            let ciimage = CIImage(image: image)
            guard let cImage = ciimage else {
                DispatchQueue.main.async {
                    if let com = completion {
                        com(nil, ErrorCode.imageEmpty)
                    }
                }
                return
            }
            
            let requestHandle = VNImageRequestHandler(ciImage: cImage, options: [:])
            let request = VNDetectFaceLandmarksRequest { (request, error) in
                
                DispatchQueue.main.async {
                    if let _ = error {
                        if let com = completion {
                            com(nil, ErrorCode.noface)
                        }
                        return
                    }
                    
                    let faces = self.transformRequestToModel(request: request, image: image)
                    if let fs = faces {
                        if let com = completion {
                            com(fs, ErrorCode.none)
                        }
                    } else {
                        if let com = completion {
                            com(nil, ErrorCode.noface)
                        }
                    }
                }
            }
            try? requestHandle.perform([request])
        }
    }
    
    fileprivate func transformRequestToModel(request: VNRequest,
                                             image: UIImage) -> [WKCVisonModel]? {
        let observations: [VNFaceObservation]? = request.results as? [VNFaceObservation]
        guard let theObservations = observations else { return nil }
        
        var faces: [WKCVisonModel] = [WKCVisonModel]()
        for observation in theObservations {
            let faceModel = WKCVisonModel()
            
            let landmarks = observation.landmarks

            let leftEyeRegion2D = landmarks?.leftEye
            faceModel.leftEye0 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: leftEyeRegion2D?.normalizedPoints[0])
            faceModel.leftEye1 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: leftEyeRegion2D?.normalizedPoints[1])
            faceModel.leftEye2 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: leftEyeRegion2D?.normalizedPoints[2])
            faceModel.leftEye3 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: leftEyeRegion2D?.normalizedPoints[3])
            faceModel.leftEye4 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: leftEyeRegion2D?.normalizedPoints[4])
            faceModel.leftEye5 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: leftEyeRegion2D?.normalizedPoints[5])
            
            let rightEyeRegion2D = landmarks?.rightEye
            faceModel.rightEye0 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: rightEyeRegion2D?.normalizedPoints[0])
            faceModel.rightEye1 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: rightEyeRegion2D?.normalizedPoints[1])
            faceModel.rightEye2 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: rightEyeRegion2D?.normalizedPoints[2])
            faceModel.rightEye3 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: rightEyeRegion2D?.normalizedPoints[3])
            faceModel.rightEye4 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: rightEyeRegion2D?.normalizedPoints[4])
            faceModel.rightEye5 = transformPoint(image: image,
                                                faceRect: observation.boundingBox,
                                                landmarkPoint: rightEyeRegion2D?.normalizedPoints[5])
            
            let leftEyeBrowRegion2D = landmarks?.leftEyebrow
            faceModel.leftEyebrow0 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: leftEyeBrowRegion2D?.normalizedPoints[0])
            faceModel.leftEyebrow1 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: leftEyeBrowRegion2D?.normalizedPoints[1])
            faceModel.leftEyebrow2 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: leftEyeBrowRegion2D?.normalizedPoints[2])
            faceModel.leftEyebrow3 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: leftEyeBrowRegion2D?.normalizedPoints[3])
            faceModel.leftEyebrow4 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: leftEyeBrowRegion2D?.normalizedPoints[4])
            faceModel.leftEyebrow5 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: leftEyeBrowRegion2D?.normalizedPoints[5])
            
            let rightEyeBrowRegion2D = landmarks?.rightEyebrow
            faceModel.rightEyebrow0 = transformPoint(image: image,
                                                     faceRect: observation.boundingBox,
                                                     landmarkPoint: rightEyeBrowRegion2D?.normalizedPoints[0])
            faceModel.rightEyebrow1 = transformPoint(image: image,
                                                     faceRect: observation.boundingBox,
                                                     landmarkPoint: rightEyeBrowRegion2D?.normalizedPoints[1])
            faceModel.rightEyebrow2 = transformPoint(image: image,
                                                     faceRect: observation.boundingBox,
                                                     landmarkPoint: rightEyeBrowRegion2D?.normalizedPoints[2])
            faceModel.rightEyebrow3 = transformPoint(image: image,
                                                     faceRect: observation.boundingBox,
                                                     landmarkPoint: rightEyeBrowRegion2D?.normalizedPoints[3])
            faceModel.rightEyebrow4 = transformPoint(image: image,
                                                     faceRect: observation.boundingBox,
                                                     landmarkPoint: rightEyeBrowRegion2D?.normalizedPoints[4])
            faceModel.rightEyebrow5 = transformPoint(image: image,
                                                     faceRect: observation.boundingBox,
                                                     landmarkPoint: rightEyeBrowRegion2D?.normalizedPoints[5])
            
            let leftEyePupilRegion2D = landmarks?.leftPupil
            faceModel.leftPupil = transformPoint(image: image,
                                                 faceRect: observation.boundingBox,
                                                 landmarkPoint: leftEyePupilRegion2D?.normalizedPoints[0])
            
            let rightEyePupilRegion2D = landmarks?.rightPupil
            faceModel.rightPupil = transformPoint(image: image,
                                                 faceRect: observation.boundingBox,
                                                 landmarkPoint: rightEyePupilRegion2D?.normalizedPoints[0])
            
            let noseRegion2D = landmarks?.nose
            faceModel.nose0 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[0])
            faceModel.nose1 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[1])
            faceModel.nose2 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[2])
            faceModel.nose3 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[3])
            faceModel.nose4 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[4])
            faceModel.nose5 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[5])
            faceModel.nose6 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[6])
            faceModel.nose7 = transformPoint(image: image,
                                             faceRect: observation.boundingBox,
                                             landmarkPoint: noseRegion2D?.normalizedPoints[7])
            
            let noseCretRegion2D = landmarks?.noseCrest
            faceModel.noseCrest0 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: noseCretRegion2D?.normalizedPoints[0])
            faceModel.noseCrest1 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: noseCretRegion2D?.normalizedPoints[1])
            faceModel.noseCrest2 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: noseCretRegion2D?.normalizedPoints[2])
            faceModel.noseCrest3 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: noseCretRegion2D?.normalizedPoints[3])
            faceModel.noseCrest4 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: noseCretRegion2D?.normalizedPoints[4])
            faceModel.noseCrest5 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: noseCretRegion2D?.normalizedPoints[5])
     
            let medianLineRegion2D = landmarks?.medianLine
            faceModel.medianLine0 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[0])
            faceModel.medianLine1 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[1])
            faceModel.medianLine2 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[2])
            faceModel.medianLine3 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[3])
            faceModel.medianLine4 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[4])
            faceModel.medianLine5 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[5])
            faceModel.medianLine6 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[6])
            faceModel.medianLine7 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[7])
            faceModel.medianLine8 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[8])
            faceModel.medianLine9 = transformPoint(image: image,
                                                   faceRect: observation.boundingBox,
                                                   landmarkPoint: medianLineRegion2D?.normalizedPoints[9])
            
            let outerLipsRegion2D = landmarks?.outerLips
            faceModel.outerLips0 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[0])
            faceModel.outerLips1 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[1])
            faceModel.outerLips2 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[2])
            faceModel.outerLips3 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[3])
            faceModel.outerLips4 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[4])
            faceModel.outerLips5 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[5])
            faceModel.outerLips6 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[6])
            faceModel.outerLips7 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[7])
            faceModel.outerLips8 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[8])
            faceModel.outerLips9 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[9])
            faceModel.outerLips10 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[10])
            faceModel.outerLips11 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[11])
            faceModel.outerLips12 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[12])
            faceModel.outerLips13 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: outerLipsRegion2D?.normalizedPoints[13])
            
            let innerLipsRegion2D = landmarks?.innerLips
            faceModel.innerLips0 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: innerLipsRegion2D?.normalizedPoints[0])
            faceModel.innerLips1 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: innerLipsRegion2D?.normalizedPoints[1])
            faceModel.innerLips2 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: innerLipsRegion2D?.normalizedPoints[2])
            faceModel.innerLips3 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: innerLipsRegion2D?.normalizedPoints[3])
            faceModel.innerLips4 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: innerLipsRegion2D?.normalizedPoints[4])
            faceModel.innerLips5 = transformPoint(image: image,
                                                  faceRect: observation.boundingBox,
                                                  landmarkPoint: innerLipsRegion2D?.normalizedPoints[5])
            
            let faceContourRegion2D = landmarks?.faceContour
            faceModel.faceContour0 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[0])
            faceModel.faceContour1 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[1])
            faceModel.faceContour2 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[2])
            faceModel.faceContour3 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[3])
            faceModel.faceContour4 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[4])
            faceModel.faceContour5 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[5])
            faceModel.faceContour6 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[6])
            faceModel.faceContour7 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[7])
            faceModel.faceContour8 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[8])
            faceModel.faceContour9 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[9])
            faceModel.faceContour10 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[10])
            faceModel.faceContour11 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[11])
            faceModel.faceContour12 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[12])
            faceModel.faceContour13 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[13])
            faceModel.faceContour14 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[14])
            faceModel.faceContour15 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[15])
            faceModel.faceContour16 = transformPoint(image: image,
                                                    faceRect: observation.boundingBox,
                                                    landmarkPoint: faceContourRegion2D?.normalizedPoints[16])
            
            faces.append(faceModel)
        }
        
        return faces
    }
    
    func transformPoint(image: UIImage,
                        faceRect: CGRect,
                        landmarkPoint: CGPoint?) -> CGPoint? {
        guard let landmarkPoint = landmarkPoint else { return nil }
        let width = image.size.width * faceRect.width
        let height = image.size.height * faceRect.height
        let x = landmarkPoint.x * width + faceRect.origin.x * image.size.width
        let y = image.size.height - (landmarkPoint.y * height + faceRect.origin.y * image.size.height)
        return CGPoint(x: x, y: y)
    }

}
