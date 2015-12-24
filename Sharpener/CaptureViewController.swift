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
    
    // MARK: UI
    @IBOutlet weak var ToolBar: UIView!
    @IBOutlet weak var imageView: CaptureImageView!
    @IBOutlet weak var controlPanel: UIView!
    @IBOutlet weak var shutterButton: ShutterButton!
    @IBOutlet weak var torchSwitch: TorchSwitcher!
    var metalView: MetalVideoView! {
        didSet {
            guard context.device != nil else { return }
            metalView.framebufferOnly = false
            // Texture for Y
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, context.device!, nil, &videoTextureCache)
        }
    }
    
    // MARK: Properties
    let context: MXNContext = MXNContext()
    var medianFilter: MedianFilter!
    var thresholdingFilter: ThresholdingFilter!
    var videoProvider: MXNVideoProvider!
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var currentCamera: AVCaptureDevicePosition = .Back
    
    let videoOutput = AVCaptureVideoDataOutput()
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var videoTextureCache: Unmanaged<CVMetalTextureCacheRef>?
    let captureSession = AVCaptureSession()
    var torchOn: Bool = false {
        didSet {
            letThereBeLight(torchOn)
        }
    }
    
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareFilters()
        prepareCameras()
        prepareMetalView()
        prepareCaptureSession()
        prepareGestures()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        connection.videoOrientation = .Portrait
        
        var textureRef : Unmanaged<CVMetalTextureRef>?
        defer { textureRef?.release() }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTextureCache!.takeUnretainedValue(),
            pixelBuffer,
            nil,
            MTLPixelFormat.BGRA8Unorm,
            width, height, 0,
            &textureRef)
        
        let texture = CVMetalTextureGetTexture((textureRef?.takeUnretainedValue())!)
        
        videoProvider.texture = texture
    }
    
    override func viewDidLayoutSubviews() {
        metalView.frame = imageView.bounds
        metalView.drawableSize = CGSizeMake(imageView.bounds.width*2, imageView.bounds.height*2)
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
    
    func letThereBeLight(light: Bool) {
        guard backCamera.hasTorch else { return }
        do {
            try backCamera.lockForConfiguration()
            backCamera.torchMode = light ? .On : .Off
            backCamera.unlockForConfiguration()
            
        } catch {
            print("Can't Lock Camera Configuration")
        }
    }
    
    // MARK: Gesture Handlers
    
    func torchSwitchClicked() {
        torchSwitch.onOffState.toggle()
        letThereBeLight(torchSwitch.onOffState.isOn())
    }
    
    func shutterClicked() {
        // grab image, segue to next view
    }
}


// MARK: - ViewDidLoad Details
extension CaptureViewController {
    private func prepareFilters() {
        medianFilter = MedianFilter(context: context, radius: 3)
        thresholdingFilter = ThresholdingFilter(context: context, thresholdingFactor: 0.5)
        videoProvider = MXNVideoProvider()
        
        thresholdingFilter.provider = medianFilter
        medianFilter.provider = videoProvider
    }
    
    private func prepareCameras() {
        let availableDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableDevices as! [AVCaptureDevice] {
            if device.position == .Front {
                frontCamera = device
            } else if device.position == .Back {
                backCamera = device
            }
        }
    }
    
    private func prepareMetalView() {
        metalView = MetalVideoView(frame: view.bounds, device: context.device!, filter: thresholdingFilter)
        imageView.addSubview(metalView)
    }
    
    private func prepareCaptureSession() {
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
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample_buffer_delegate", DISPATCH_QUEUE_SERIAL))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        captureSession.startRunning()
    }
    
    private func prepareGestures() {
        shutterButton.addTarget(self, action: "shutterClicked", forControlEvents: .TouchUpInside)
        torchSwitch.addTarget(self, action: "torchSwitchClicked", forControlEvents: .TouchUpInside)
    }
}