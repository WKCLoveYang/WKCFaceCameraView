//
//  WKCFaceVideoRecordEncoder.swift
//  SwiftFuck
//
//  Created by wkcloveYang on 2020/7/23.
//  Copyright © 2020 wkcloveYang. All rights reserved.
//

import UIKit
import AVFoundation

open class WKCFaceVideoRecordEncoder: NSObject {

   public convenience init(path: String,
                           height: Int,
                           width: Int,
                           channels: Int,
                           smaples: CGFloat) {
        self.init()
        
        savePath = path
        
        try? FileManager.default.removeItem(atPath: path)
        let url = URL(fileURLWithPath: path)
        writer = try? AVAssetWriter(url: url, fileType: .mp4)
        writer?.shouldOptimizeForNetworkUse = true
        
        initVideo(height: height, width: width)
        if channels != 0 && smaples != 0 {
            initAudio(channels: channels, samples: smaples)
        }
    }
    
    public var savePath: String!
    
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    
    private func initVideo(height: Int,
                           width: Int) {
        let settings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
            ] as [String : Any]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        videoInput?.expectsMediaDataInRealTime = true
        guard let input = videoInput else { return }
        writer?.add(input)
    }
    
    private func initAudio(channels: Int,
                           samples: CGFloat) {
        let settings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: channels,
            AVSampleRateKey: samples,
            AVEncoderBitRateKey: 128000
            ] as [String : Any]
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        audioInput?.expectsMediaDataInRealTime = true
        guard let audio = audioInput else { return }
        writer?.add(audio)
    }

    public func finish(completion: ((WKCFaceVideoRecordEncoder) -> ())?) {
        guard let wri = writer else { return }
        if wri.status == .writing {
            wri.finishWriting { [weak self] in
                if let com = completion, let weakself = self {
                    com(weakself)
                }
            }
        }
    }
    
    @discardableResult public func encode(frame: CMSampleBuffer,
                                          isVideo: Bool) -> Bool {
        if CMSampleBufferDataIsReady(frame) {
            if writer!.status == .unknown && isVideo {
                let startTime = CMSampleBufferGetPresentationTimeStamp(frame)
                writer!.startWriting()
                writer!.startSession(atSourceTime: startTime)
            }
            
            if writer!.status == .failed {
                return false
            }
            
            if isVideo {
                if videoInput!.isReadyForMoreMediaData {
                    videoInput!.append(frame)
                    return true
                }
            } else {
                if audioInput!.isReadyForMoreMediaData {
                    audioInput!.append(frame)
                    return true
                }
            }
        }
        return false
    }
}
