//
//  WKCVisonModel.swift
//  MLKitFace
//
//  Created by wkcloveYang on 2020/9/29.
//  Copyright © 2020 wkcloveYang. All rights reserved.
//

import UIKit

open class WKCVisonModel: NSObject {
    
    // 左眼(9点钟方向开始, 顺时针转)
    public var leftEye0: CGPoint?
    public var leftEye1: CGPoint?
    public var leftEye2: CGPoint?
    public var leftEye3: CGPoint?
    public var leftEye4: CGPoint?
    public var leftEye5: CGPoint?
    
    // 右眼(3点钟方向开始, 逆时针转)
    public var rightEye0: CGPoint?
    public var rightEye1: CGPoint?
    public var rightEye2: CGPoint?
    public var rightEye3: CGPoint?
    public var rightEye4: CGPoint?
    public var rightEye5: CGPoint?
    
    // 左眉毛(9点钟方向开始, 顺时针转)
    public var leftEyebrow0: CGPoint?
    public var leftEyebrow1: CGPoint?
    public var leftEyebrow2: CGPoint?
    public var leftEyebrow3: CGPoint?
    public var leftEyebrow4: CGPoint?
    public var leftEyebrow5: CGPoint?
    
    // 右眉毛(9点钟方向开始, 顺时针转)
    public var rightEyebrow0: CGPoint?
    public var rightEyebrow1: CGPoint?
    public var rightEyebrow2: CGPoint?
    public var rightEyebrow3: CGPoint?
    public var rightEyebrow4: CGPoint?
    public var rightEyebrow5: CGPoint?
    
    // 左瞳孔
    public var leftPupil: CGPoint?
    
    // 右瞳孔
    public var rightPupil: CGPoint?
    
    // 鼻子(从两眼间的鼻梁中间开始, 逆时针转)
    public var nose0: CGPoint?
    public var nose1: CGPoint?
    public var nose2: CGPoint?
    public var nose3: CGPoint?
    public var nose4: CGPoint?
    public var nose5: CGPoint?
    public var nose6: CGPoint?
    public var nose7: CGPoint?
    
    // 鼻子轮廓(与鼻子差不多)
    public var noseCrest0: CGPoint?
    public var noseCrest1: CGPoint?
    public var noseCrest2: CGPoint?
    public var noseCrest3: CGPoint?
    public var noseCrest4: CGPoint?
    public var noseCrest5: CGPoint?
    
    // 中心线(从两眼间的鼻梁中间开始,向下至下巴)
    public var medianLine0: CGPoint?
    public var medianLine1: CGPoint?
    public var medianLine2: CGPoint?
    public var medianLine3: CGPoint?
    public var medianLine4: CGPoint?
    public var medianLine5: CGPoint?
    public var medianLine6: CGPoint?
    public var medianLine7: CGPoint?
    public var medianLine8: CGPoint?
    public var medianLine9: CGPoint?
    
    // 外唇(9点钟方向开始, 顺指针转)
    public var outerLips0: CGPoint?
    public var outerLips1: CGPoint?
    public var outerLips2: CGPoint?
    public var outerLips3: CGPoint?
    public var outerLips4: CGPoint?
    public var outerLips5: CGPoint?
    public var outerLips6: CGPoint?
    public var outerLips7: CGPoint?
    public var outerLips8: CGPoint?
    public var outerLips9: CGPoint?
    public var outerLips10: CGPoint?
    public var outerLips11: CGPoint?
    public var outerLips12: CGPoint?
    public var outerLips13: CGPoint?
    
    // 内唇(方向同外唇)
    public var innerLips0: CGPoint?
    public var innerLips1: CGPoint?
    public var innerLips2: CGPoint?
    public var innerLips3: CGPoint?
    public var innerLips4: CGPoint?
    public var innerLips5: CGPoint?
    
    // 脸轮廓(3点钟方向开始, 顺指针转)
    public var faceContour0: CGPoint?
    public var faceContour1: CGPoint?
    public var faceContour2: CGPoint?
    public var faceContour3: CGPoint?
    public var faceContour4: CGPoint?
    public var faceContour5: CGPoint?
    public var faceContour6: CGPoint?
    public var faceContour7: CGPoint?
    public var faceContour8: CGPoint?
    public var faceContour9: CGPoint?
    public var faceContour10: CGPoint?
    public var faceContour11: CGPoint?
    public var faceContour12: CGPoint?
    public var faceContour13: CGPoint?
    public var faceContour14: CGPoint?
    public var faceContour15: CGPoint?
    public var faceContour16: CGPoint?
    
    // 两眉毛中间
    public var eyebrowMiddle: CGPoint? {
        guard let left = leftEyebrow3, let right = rightEyebrow3 else { return nil }
        return CGPoint(x: (left.x + right.x) / 2.0, y: (left.y + right.y) / 2.0)
    }
    
    // 左脸中心
    public var leftFaceCenter: CGPoint? {
        guard let leftEye0 = leftEye0, let outLip0 = outerLips0 else { return nil }
        return CGPoint(x: (leftEye0.x + outLip0.x) / 2.0, y: (leftEye0.y + outLip0.y) / 2.0)
    }
    
    // 右脸中心
    public var rightFaceCenter: CGPoint? {
        guard let rightEye0 = rightEye0, let outLip7 = outerLips7 else { return nil }
        return CGPoint(x: (rightEye0.x + outLip7.x) / 2.0, y: (rightEye0.y + outLip7.y) / 2.0)
    }
    
    // 鼻子左侧中心点
    public var leftNoseCenter: CGPoint? {
        guard let eyeBrowMiddle = eyebrowMiddle, let nose2 = nose2 else { return nil }
        return CGPoint(x: (eyeBrowMiddle.x + nose2.x) / 2.0, y: (eyeBrowMiddle.y + nose2.y) / 2.0)
    }
    
    // 鼻子右侧中心点
    public var rightNoseCenter: CGPoint? {
        guard let eyeBrowMiddle = eyebrowMiddle, let nose6 = nose6 else { return nil }
        return CGPoint(x: (eyeBrowMiddle.x + nose6.x) / 2.0, y: (eyeBrowMiddle.y + nose6.y) / 2.0)
    }
}
