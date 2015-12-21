//
//  CaptureViewController.swift
//  Sharpener
//
//  Created by Inti Guo on 12/20/15.
//  Copyright © 2015 Inti Guo. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import MetalKit

class CaptureViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let context: MXNContext = MXNContext()
    var redOnlyFilter: RedOnlyFilter!
    var ycbcrFilter: YCbCrConvertFilter!
    
    var metalView: MetalVideoView! {
        didSet {
            guard context.device != nil else { return }
            metalView.framebufferOnly = false
            // Texture for Y
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, context.device!, nil, &videoTextureCache)
            // Texture for CbCr
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, context.device!, nil, &videoTextureCache)
        }
    }
    var videoTextureCache: Unmanaged<CVMetalTextureCacheRef>?
    let captureSession = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        redOnlyFilter = RedOnlyFilter(context: context)
        ycbcrFilter = YCbCrConvertFilter(context: context)
        redOnlyFilter.provider = ycbcrFilter
        
        metalView = MetalVideoView(frame: CGRectZero, device: context.device!, filter: redOnlyFilter)
        view.addSubview(metalView)
        
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            print("Can't Access Camera")
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
    
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        connection.videoOrientation = .Portrait
        
        var yTextureRef : Unmanaged<CVMetalTextureRef>?
        
        let yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTextureCache!.takeUnretainedValue(),
            pixelBuffer,
            nil,
            MTLPixelFormat.R8Unorm,
            yWidth, yHeight, 0,
            &yTextureRef)
        
        var cbcrTextureRef: Unmanaged<CVMetalTextureRef>?
        let cbcrWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let cbcrHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTextureCache!.takeUnretainedValue(),
            pixelBuffer,
            nil,
            .RG8Unorm, cbcrWidth, cbcrHeight, 1,
            &cbcrTextureRef)
        
        let yTexture = CVMetalTextureGetTexture((yTextureRef?.takeUnretainedValue())!)
        let cbcrTexture = CVMetalTextureGetTexture((cbcrTextureRef?.takeUnretainedValue())!)
        
        ycbcrFilter.yTexture = yTexture
        ycbcrFilter.cbcrTexture = cbcrTexture
        
        yTextureRef?.release()
        cbcrTextureRef?.release()
    }
    
    override func viewDidLayoutSubviews() {
        metalView.frame = view.bounds
        metalView.drawableSize = CGSizeMake(view.bounds.width*2, view.bounds.height*2)
    }

}