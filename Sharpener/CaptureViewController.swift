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
    
    // MARK: Properties
    let context: MXNContext = MXNContext()
    var redOnlyFilter: RedOnlyFilter!
    var ycbcrFilter: YCbCrConvertFilter!
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var currentCamera: AVCaptureDevicePosition = .Back
    
    let videoOutput = AVCaptureVideoDataOutput()
    let stillImageOutput = AVCaptureStillImageOutput()
    
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
    
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareFilters()
        prepareCameras()
        prepareMetalView()
        prepareCaptureSession()
    }
    
    func prepareFilters() {
        redOnlyFilter = RedOnlyFilter(context: context)
        ycbcrFilter = YCbCrConvertFilter(context: context)
        redOnlyFilter.provider = ycbcrFilter
    }
    
    func prepareCameras() {
        let availableDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableDevices as! [AVCaptureDevice] {
            if device.position == .Front {
                frontCamera = device
            } else if device.position == .Back {
                backCamera = device
            }
        }
    }
    
    func prepareMetalView() {
        metalView = MetalVideoView(frame: view.bounds, device: context.device!, filter: redOnlyFilter)
        view.addSubview(metalView)
    }
    
    func prepareCaptureSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            print("Can't Access Camera")
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample_buffer_delegate", DISPATCH_QUEUE_SERIAL))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        captureSession.startRunning()
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        connection.videoOrientation = .Portrait
        
        var yTextureRef : Unmanaged<CVMetalTextureRef>?
        defer { yTextureRef?.release() }
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
        defer { cbcrTextureRef?.release() }
        let cbcrWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let cbcrHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTextureCache!.takeUnretainedValue(),
            pixelBuffer,
            nil,
            MTLPixelFormat.RG8Unorm,
            cbcrWidth, cbcrHeight, 1,
            &cbcrTextureRef)
        
        let yTexture = CVMetalTextureGetTexture((yTextureRef?.takeUnretainedValue())!)
        let cbcrTexture = CVMetalTextureGetTexture((cbcrTextureRef?.takeUnretainedValue())!)
        
        ycbcrFilter.yTexture = yTexture
        ycbcrFilter.cbcrTexture = cbcrTexture
    }
    
    override func viewDidLayoutSubviews() {
        metalView.frame = view.bounds
        metalView.drawableSize = CGSizeMake(view.bounds.width*2, view.bounds.height*2)
    }
    
    
    // MARK: Actions
    func switchCameraInput() {
        var removeInput, addInput : AVCaptureDeviceInput
        do {
            removeInput = try AVCaptureDeviceInput(device: (currentCamera == .Front ? frontCamera : backCamera))
        } catch {
            print("Can't Access Camera")
            return
        }
        do {
            addInput = try AVCaptureDeviceInput(device: (currentCamera == .Front ? backCamera : frontCamera))
        } catch {
            print("Can't Access Camera")
            return
        }
        captureSession.removeInput(removeInput)
        captureSession.addInput(addInput)
        currentCamera = currentCamera == .Front ? .Back : .Front
    }
}