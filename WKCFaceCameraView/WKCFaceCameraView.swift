//
//  WKCFaceCameraView.swift
//  SwiftFuck
//
//  Created by wkcloveYang on 2020/7/23.
//  Copyright © 2020 wkcloveYang. All rights reserved.
//

import UIKit
import AVFoundation

@objc public protocol WKCFaceCameraViewDelegate: NSObjectProtocol {
    
    /// 流回调
    /// - Parameters:
    ///   - face: camera
    ///   - sampleBuffer: 流
    @objc optional func faceCameraDidOutputVideoBuffer(face: WKCFaceCameraView, sampleBuffer: CMSampleBuffer)
    
    /// 拍照
    /// - Parameters:
    ///   - face: camera
    ///   - image: 照片
    @objc optional func faceCameraDidTakePhoto(face: WKCFaceCameraView, image: UIImage)
    
    /// 录像
    /// - Parameters:
    ///   - face: camera
    ///   - videoPath: 路径
    @objc optional func faceCameraDidVideoRecorded(face: WKCFaceCameraView, videoPath: String)
    
    /// 聚焦
    /// - Parameters:
    ///   - face: camera
    ///   - point: 聚焦点
    @objc optional func faceCameraDidFocus(face: WKCFaceCameraView, point: CGPoint)
    
    /// 缩放
    /// - Parameters:
    ///   - face: camera
    ///   - zoom: 缩放比例
    @objc optional func faceCameraDidZoom(face: WKCFaceCameraView, zoom: CGFloat)

    /// 脸识别结束
    /// - Parameters:
    ///   - face: camera
    ///   - isSuccess: 是否成功
    @objc optional func faceCameraDidEndFaceDetect(face: WKCFaceCameraView, isSuccess: Bool)
}



public class WKCFaceCameraView: UIView {

    /// 闪光灯改变的通知
    public static let flashChangedNotification: String = "com.flash.changed"
    /// 闪光灯通知info内包含的信息 -> Bool
    public static let isFlashOnKey: String = "com.is.flash.on"
    
    /// 模式 拍照还是录像
    public enum Feature: Int {
        case photo = 0
        case video = 1
    }
    
    public weak var delegate: WKCFaceCameraViewDelegate?
    
    /// 模式(拍照;录像)
    public var mode: Feature = .photo {
        willSet {
            if newValue == .video {
                removeAudio()
                removeMic()
                addAudio()
                addMic()
            }
            
            beginZoomScale = 1.0
            zoom(scale: 0)
        }
    }
    
    /// 摄像头位置
    public var position: AVCaptureDevice.Position = .front
    
    /// 是否摄像头前置
    public var isFront: Bool {
        return position == AVCaptureDevice.Position.front
    }
    
    /// 是否正在捕捉画面
    public var isCapturing: Bool {
        if let ss = session {
            return ss.isRunning
        }
        return false
    }
    
    /// 是否点击聚焦
    public var shouldTapFocus: Bool = true {
        willSet {
            tapGesture.isEnabled = newValue
        }
    }
    
    /// 是否支持捏合缩放
    public var shouldPinchZoomEnable: Bool = true {
        willSet {
            pinchGesture.isEnabled = newValue
        }
    }
    
    /// 最大缩放比例
    public var maxZoomScale: CGFloat = 3.0
    
    /// 聚焦点
    public var focusPoint: CGPoint = .zero {
        willSet {
            guard let device = captureDecive else { return }
            if !device.isFocusPointOfInterestSupported {
                return
            }
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = newValue
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            } catch _ {
                
            }
        }
    }
    
    /// 曝光点
    public var exposurePoint: CGPoint = .zero {
        willSet {
            guard let device = captureDecive else { return }
            if !device.isExposurePointOfInterestSupported {
                return
            }
            do {
                try device.lockForConfiguration()
                device.exposureMode = .locked
                device.exposurePointOfInterest = newValue
                device.exposureMode = .continuousAutoExposure
                device.unlockForConfiguration()
            } catch _ {
                
            }
        }
    }
    
    /// 闪光灯默认
    public var flashMode: AVCaptureDevice.TorchMode {
        set {
            guard let device = captureDecive else { return }
            do {
                try device.lockForConfiguration()
                if newValue == .on || newValue == .auto {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch _ {
                
            }
        }
        
        get {
            return captureDecive!.torchMode
        }
    }
    
    /// 是否使用人脸识别
    public var isFaceEnable: Bool = true
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(blurView)
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(pinchGesture)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        previewLayer.frame = bounds
        blurView.frame = bounds
    }
    
    private var faceIndex: Int = 0
    
    private enum RunningMode: Int {
        case common        = 0
        case takePhoto     = 1
        case videoRecord   = 2
        case videoRecorded = 3
    }
    
    private var captureFormat: OSType = kCVPixelFormatType_32BGRA
    private var runningMode: RunningMode = .common
    private var videoPath: String = ""
    private var recordEncoder: WKCFaceVideoRecordEncoder?
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(actionGesture(sender:)))
        return gesture
    }()
    private lazy var pinchGesture: UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(actionPinch(sender:)))
        gesture.delegate = self
        return gesture
    }()
    private var beginZoomScale: CGFloat = 1.0
    private var zoomScale: CGFloat = 1.0
    

    private lazy var captureDecive: AVCaptureDevice? = {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position).devices
        var device: AVCaptureDevice?
        for item in devices {
            if item.position == position {
                device = item
            }
        }
        return device
    }()
    
    private lazy var frontCameraInput: AVCaptureDeviceInput? = {
        guard let front = captureDevice(position: .front) else {
            debugPrint("====== Error: frontCameraDevice is nil!!! ======")
            return nil
        }
        do {
           let input = try AVCaptureDeviceInput(device: front)
            captureDecive = input.device
            return input
        } catch _ {
            debugPrint("====== Error: frontCameraInput is nil!!! ======")
            return nil
        }
    }()
    
    private lazy var backCameraInput: AVCaptureDeviceInput? = {
        guard let back = captureDevice() else {
            debugPrint("====== Error: backCameraDevice is nil!!! ======")
            return nil
        }
        do {
           let input = try AVCaptureDeviceInput(device: back)
            captureDecive = input.device
            return input
        } catch _ {
            debugPrint("====== Error: backCameraInput is nil!!! ======")
            return nil
        }
    }()
    
    private lazy var videoCaptureQueue: DispatchQueue = DispatchQueue(label: "com.nama.videoCaptureQueue")
      
    private lazy var audioCaptureQueue: DispatchQueue = DispatchQueue(label: "com.nama.audioCaptureQueue")
      
    private lazy var videoOuput: AVCaptureVideoDataOutput? = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: captureFormat]
        output.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        return output
    }()
      
    private lazy var audioMicInput: AVCaptureDeviceInput? = {
        let mic = AVCaptureDevice.default(for: .audio)
        guard let m = mic else { return nil }
        let input = try? AVCaptureDeviceInput(device: m)
        return input
    }()
      
    private lazy var audioOutput: AVCaptureAudioDataOutput? = {
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: audioCaptureQueue)
        return output
    }()
    
    private lazy var session: AVCaptureSession? = {
        let session = AVCaptureSession()

        if mode == .video {
            if session.canSetSessionPreset(.hd4K3840x2160) {
                session.sessionPreset = .hd4K3840x2160
            } else if session.canSetSessionPreset(.hd1920x1080) {
                session.sessionPreset = .hd1920x1080
            } else if session.canSetSessionPreset(.hd1280x720) {
                session.sessionPreset = .hd1280x720
            } else {
                session.sessionPreset = .high
            }
        } else {
            session.sessionPreset = .high
        }

        let deviceInput = isFront ? self.frontCameraInput : self.backCameraInput
    
        if let input = deviceInput {
            if session.canAddInput(input) {
                session.addInput(input)
            }
        }
          
        if let videoOutput = videoOuput {
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        }
          
        let videoConnection = videoOuput?.connection(with: .video)
        videoConnection?.automaticallyAdjustsVideoMirroring = false
        if let connection = videoConnection {
            connection.videoOrientation = .portrait
            if connection.isVideoMirroringSupported && isFront {
                connection.isVideoMirrored = true
            }
        }
          
        guard let input = deviceInput else { return session }
        session.beginConfiguration()
        do {
            try input.device.lockForConfiguration()
            input.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
            input.device.unlockForConfiguration()
            session.commitConfiguration()
        } catch _ {
            session.commitConfiguration()
            return session
        }
          
        return session
      }()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let player = AVCaptureVideoPreviewLayer(session: session!)
        player.videoGravity = .resizeAspectFill
        player.frame = bounds
        return player
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        view.frame = bounds
        view.isHidden = true
        view.layer.zPosition = 1
        return view
    }()
    
    
    /// 开始捕捉画面
   open func startCapture() {
        mode = .photo
        guard let ses = session else { return }
        if !ses.isRunning {
            if previewLayer.superlayer == nil {
                layer.addSublayer(previewLayer)
            }
            ses.startRunning()
        }
    }
    
    /// 停止捕捉画面
    open func stopCapture() {
        guard let ses = session else { return }
        if ses.isRunning {
            ses.stopRunning()
        }
    }
    
    /// 开始录像
    /// - Parameter filePath: 自定义路径
    open func startVideoRecord(filePath: String? = nil) {
        if let path = filePath {
            videoPath = path
        } else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYYMMddhhmmssSS"
            let dateString = formatter.string(from: date)
            let path = NSTemporaryDirectory() + "/\(dateString).mp4"
            videoPath = path
        }
        mode = .video
        runningMode = .videoRecord
        startCapture()
    }
    
    /// 停止录像
    open func stopVideoRecord() {
        if runningMode == .common {
            finishRecordVideo()
            return
        }
        
        runningMode = .videoRecorded
    }
    
    /// 销毁路径内的录像
    open func inviladeVideoRecord() {
        runningMode = .common
        try? FileManager.default.removeItem(atPath: videoPath)
        recordEncoder = nil
    }
    
    /// 切换摄像头
    open func switchCamera() {
        guard let ses = session else { return }
        ses.stopRunning()
        
        guard let back = backCameraInput else { return }
        guard let front = frontCameraInput else { return }
        
        if !isFront {
            ses.removeInput(back)
            if ses.canAddInput(front) {
                ses.addInput(front)
            }
            position = .front
        } else {
            ses.removeInput(front)
            if ses.canAddInput(back) {
                ses.addInput(back)
            }
            position = .back
        }
        
        let deviceInput = isFront ? front : back
        ses.beginConfiguration()
        do {
            try deviceInput.device.lockForConfiguration()
            deviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
            deviceInput.device.unlockForConfiguration()
            ses.commitConfiguration()
        } catch _ {
            ses.commitConfiguration()
        }
        
        let videoConnection = videoOuput?.connection(with: .video)
        videoConnection?.automaticallyAdjustsVideoMirroring = false
        if let connection = videoConnection {
            connection.videoOrientation = .portrait
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = isFront
            }
        }
    
        ses.startRunning()
        
        beginZoomScale = 1.0
        zoom(scale: 0)

        if isFront {
            NotificationCenter.default.post(name: NSNotification.Name(WKCFaceCameraView.flashChangedNotification), object: nil, userInfo: [WKCFaceCameraView.isFlashOnKey : false])
        }
    }
    
    /// 切换闪光灯
    open func switchFalsh(completion: ((Bool) -> ())? = nil) {
        if isFront {
            debugPrint("Error: 前置摄像头时不能切换闪光灯!!!")
            if let com = completion {
                com(false)
            }
            return
        }
        
        if flashMode == .auto || flashMode == .off {
            flashMode = .on
        } else {
            flashMode = .off
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(WKCFaceCameraView.flashChangedNotification), object: nil, userInfo: [WKCFaceCameraView.isFlashOnKey: (flashMode == .on)])
        
        if let com = completion {
            com(true)
        }
    }
    
    /// 拍照
    open func takePhoto() {
        guard let ses = session else { return }
        if !ses.isRunning {
            return
        }
        
        runningMode = .takePhoto
        
        if isFront {
            let window = UIApplication.shared.windows.first
            guard let win = window else { return }
            let whiteView = UIView(frame: win.bounds)
            whiteView.backgroundColor = UIColor.white
            whiteView.alpha = 0.3
            
            win.addSubview(whiteView)
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                whiteView.alpha = 1.0
            }) { (_) in
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                    whiteView.alpha = 0.0
                }) { (_) in
                    whiteView.removeFromSuperview()
                }
            }
        }
    }
    
    /// 设置曝光值
    /// - Parameter value: 值
    open func setExposure(value: Float) {
        guard let device = captureDecive else { return }
        do {
            try device.lockForConfiguration()
            device.exposureMode = .continuousAutoExposure
            device.setExposureTargetBias(value, completionHandler: nil)
            device.unlockForConfiguration()
        } catch _ {
            
        }
    }
    
    /// 重置坐标
    /// - Parameters:
    ///   - frame: newFrame
    ///   - animation: 动画回调
    ///   - completion: 完成回调
    open func resetFrame(frame: CGRect,
                    animation: (() -> ())? = nil,
                    completion: (() -> ())? = nil) {
        blurView.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
            self.frame = frame
            if let ani = animation {
                ani()
            }
        }) { (finished) in
            self.blurView.isHidden = true
            if finished, let com = completion {
                com()
            }
        }
    }
    
}


extension WKCFaceCameraView: UIGestureRecognizerDelegate {
    private func captureDevice(position: AVCaptureDevice.Position = .back) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position).devices
        for item in devices {
            if item.position == position {
                return item
            }
        }
        return nil
    }
    
    private func removeMic() {
        guard let mic = audioMicInput else { return }
        session?.removeInput(mic)
    }
    
    private func removeAudio() {
        guard let audio = audioOutput else { return }
        session?.removeOutput(audio)
    }
    
    private func addMic() {
        guard let ses = session else { return }
        guard let mic = audioMicInput else { return }
        if ses.canAddInput(mic) {
            ses.addInput(mic)
        }
    }
    
    private func addAudio() {
        guard let ses = session else { return }
        guard let audio = audioOutput else { return }
        if ses.canAddOutput(audio) {
            ses.addOutput(audio)
        }
    }
    
    private func finishRecordVideo() {
        recordEncoder = nil
        if let d = delegate, d.responds(to: #selector(WKCFaceCameraViewDelegate.faceCameraDidVideoRecorded(face:videoPath:))) {
            d.faceCameraDidVideoRecorded?(face: self, videoPath: videoPath)
        }
    }
    
    private func zoom(scale: CGFloat) {
        do {
            try captureDecive?.lockForConfiguration()
            zoomScale = max(1.0, min(beginZoomScale * scale, maxZoomScale))
            captureDecive?.videoZoomFactor = zoomScale
            captureDecive?.unlockForConfiguration()
            
            if let d = delegate, d.responds(to: #selector(WKCFaceCameraViewDelegate.faceCameraDidZoom(face:zoom:))) {
                d.faceCameraDidZoom?(face: self, zoom: zoomScale)
            }
        } catch {
            debugPrint("Error locking configuration")
        }
    }
    
    @objc private func actionGesture(sender: UITapGestureRecognizer) {
        let center = sender.location(in: self)
        let point = CGPoint(x: center.y / bounds.size.height, y: isFront ? (center.x / bounds.size.width) : (1 - center.x / bounds.size.width))
        focusPoint = point
        exposurePoint = point
        
        if let d = delegate, d.responds(to: #selector(WKCFaceCameraViewDelegate.faceCameraDidFocus(face:point:))) {
            d.faceCameraDidFocus?(face: self, point: point)
        }
    }
    
    @objc private func actionPinch(sender: UIPinchGestureRecognizer) {
        zoom(scale: sender.scale)
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginZoomScale = zoomScale
        }
        return true
    }
}


// MARK: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
extension WKCFaceCameraView: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
   public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let audio = audioOutput, audio == output {
            if runningMode == .videoRecord {
                guard let encoder = recordEncoder else { return }
                encoder.encode(frame: sampleBuffer, isVideo: false)
            }
            
            return
        }
        
        if let d = delegate, d.responds(to: #selector(WKCFaceCameraViewDelegate.faceCameraDidOutputVideoBuffer(face:sampleBuffer:))) {
            d.faceCameraDidOutputVideoBuffer?(face: self, sampleBuffer: sampleBuffer)
        }
       
       
       if isFaceEnable {
           faceIndex += 1
           
           if faceIndex % 5 == 0 {
               faceIndex = 0
               
               let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
               if let imageBuffer = buffer {
                   WKCVisonManager.shared.detectFaces(buffer: imageBuffer) { isSuccess in
                       if !self.isFaceEnable { return }
                       
                       self.delegate?.faceCameraDidEndFaceDetect?(face: self, isSuccess: isSuccess)
                   }
               }
           }
       }
        
        if runningMode == .takePhoto {
            runningMode = .common
            let buffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
            stopCapture()
            guard let buf = buffer else { return }
            let image = WKCFaceBufferHelper.image(buffer: buf)
            
            if let d = delegate, d.responds(to: #selector(WKCFaceCameraViewDelegate.faceCameraDidTakePhoto(face:image:))), let img = image {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    if let result = self.cutout(image: img) {
                        d.faceCameraDidTakePhoto?(face: self, image: result)
                    }
                }
            }
        } else if runningMode == .videoRecord {
            if recordEncoder == nil {
                let buffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
                guard let buf = buffer else { return }
                let frameWidth = CVPixelBufferGetWidth(buf)
                let frameHeight = CVPixelBufferGetHeight(buf)
                if frameWidth != 0 && frameHeight != 0 {
                    recordEncoder = WKCFaceVideoRecordEncoder(path: videoPath, height: frameHeight, width: frameWidth, channels: 1, smaples: 44100)
                    return
                }
            }
            
            recordEncoder!.encode(frame: sampleBuffer, isVideo: true)
        } else if runningMode == .videoRecorded {
            runningMode = .common
            guard let encoder = recordEncoder else { return }
            encoder.finish { [weak self](coder) in
                self?.finishRecordVideo()
            }
        }
    }
    
    private func cutout(image: UIImage) -> UIImage? {
        superview?.layoutIfNeeded()
        
        let size = frame.size
        let viewWidth: CGFloat = size.width
        let viewHeight: CGFloat = size.height
        let imageWidth: CGFloat = image.size.width
        let imageHeight: CGFloat = image.size.height
        
        var x: CGFloat = 0, y: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0
        
        if viewWidth / viewHeight > imageWidth / imageHeight {
            width = imageWidth
            height = width * viewHeight / viewWidth
            y = (imageHeight - height) / 2.0
        } else {
            height = imageHeight
            width = height * viewWidth / viewHeight
            x = (imageWidth - width) / 2.0
        }
        
        return crop(at: CGRect(x: x, y: y, width: width, height: height), image: image)
    }
    
    private func crop(at rect: CGRect,
                      image: UIImage) -> UIImage? {
        let origin = CGPoint(x: -rect.origin.x, y: -rect.origin.y)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        image.draw(at: origin)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}
