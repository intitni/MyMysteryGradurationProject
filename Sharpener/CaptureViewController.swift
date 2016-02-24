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
    @IBOutlet weak var ToolBar: UIView! {
        didSet {
            ToolBar.backgroundColor = UIColor.spGrayishWhiteColor()
        }
    }
    @IBOutlet weak var imageView: CaptureImageView!
    @IBOutlet weak var controlPanel: UIView! {
        didSet {
            controlPanel.backgroundColor = UIColor.spGrayishWhiteColor().colorWithAlphaComponent(0.7)
        }
    }
    @IBOutlet weak var shutterButton: ShutterButton!
    @IBOutlet weak var torchSwitch: TorchSwitcher!
    @IBOutlet weak var cancelButton: CancelCaptureButton! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: "cancelCapture")
            cancelButton.addGestureRecognizer(tap)
        }
    }
    var metalView: MetalVideoView! {
        didSet {
            imageView.addSubview(metalView)
            guard context.device != nil else { return }
            metalView.framebufferOnly = false
            // Texture for Y
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, context.device!, nil, &videoTextureCache)
        }
    }
    var filterControlView: FilterControlView! {
        didSet {
            imageView.addSubview(filterControlView)
            filterControlView.snp_makeConstraints { make in
                make.edges.equalTo(imageView)
            }
        }
    }
    
    // MARK: Properties
    var loaded: Bool = false
    
    let context: MXNContext = MXNContext()
    var medianFilter: MedianFilter!
    var thresholdingFilter: ThresholdingFilter!
    var lineShapeFilteringFilter: LineShapeFilterFilteringFilter!
    var lineShapeRe: LineShapeRefiningFilter!
    var videoProvider: MXNVideoProvider!
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var currentCamera: AVCaptureDevicePosition = .Back
    
    let videoOutput = AVCaptureVideoDataOutput()
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var stillImage: UIImage?
    
    var videoTextureCache: Unmanaged<CVMetalTextureCacheRef>?
    let captureSession = AVCaptureSession()
    var torchOn: Bool = false {
        didSet {
            letThereBeLight(torchOn)
        }
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareFilters()
        prepareCameras()
        prepareMetalView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().idleTimerDisabled = false
        metalView.shouldDraw = false
        previewLayer.connection.enabled = false
        dispatch_async(GCD.userInitiatedQueue) {
            self.captureSession.stopRunning()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidDisappear(animated)
        if !loaded {
            prepareCaptureSession()
            prepareGestures()
            loaded = true
        }
        captureSession.startRunning()
        previewLayer.connection.enabled = true
        metalView.shouldDraw = true
    }
    
    @IBAction func unwindToCapture(sender: UIStoryboardSegue) {}
    
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
        previewLayer.connection.enabled = false
        var videoConnection : AVCaptureConnection?
        for connection in stillImageOutput.connections {
            for port in connection.inputPorts! {
                if port.mediaType == AVMediaTypeVideo {
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
            if videoConnection != nil { break }
        }
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
            (imageSampleBuffer, _) in
            
            let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
            self.stillImage = UIImage(data: imageDataJpeg)
            self.performSegueWithIdentifier("CaptureToRefine", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "CaptureToRefine":
            let destination = segue.destinationViewController as? RefineViewController
            destination?.incomeImage = stillImage
        default: break
        }
    }
    
    func cancelCapture() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}


// MARK: - ViewDidLoad Details
extension CaptureViewController {
    private func prepareFilters() {
        medianFilter = MedianFilter(context: context, radius: 1)
        thresholdingFilter = ThresholdingFilter(context: context, thresholdingFactor: 0.2)
        lineShapeFilteringFilter = LineShapeFilterFilteringFilter(context: context, threshold: 5, radius: 4)
        videoProvider = MXNVideoProvider()
        
        lineShapeRe = LineShapeRefiningFilter(context: context, radius: 8)
        
        lineShapeRe.provider = lineShapeFilteringFilter
        lineShapeFilteringFilter.provider = medianFilter
        thresholdingFilter.provider = videoProvider
        medianFilter.provider = thresholdingFilter
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
        metalView = MetalVideoView(frame: view.bounds, device: context.device!, filter: lineShapeRe)
        filterControlView = FilterControlView(frame: imageView.bounds, threshold: 0.2, lineWidth: 3, gearCount: 5)
        filterControlView.delegate = self
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
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
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
        
        do {
            try backCamera.lockForConfiguration()
            backCamera.activeVideoMinFrameDuration = CMTimeMake(1, 20)
            backCamera.unlockForConfiguration()
        } catch {
            print("Can't Lock Camera Configuration")
        }
        
        captureSession.startRunning()
    }
    
    private func prepareGestures() {
        shutterButton.addTarget(self, action: "shutterClicked", forControlEvents: .TouchUpInside)
        torchSwitch.addTarget(self, action: "torchSwitchClicked", forControlEvents: .TouchUpInside)
    }
}

extension CaptureViewController: SPSliderDelegate {
    
    private func lineWidthFromValue(value: Double) -> Int {
        let gearCount = 5.0
        let step = 1.0 / gearCount
        return Int(value / step) + 1
    }
    
    func sliderValueDidChangedTo(value: Double, forTag tag: String) {
        switch tag {
        case "threshold":
            thresholdingFilter.thresholdingFactor = Float(value)
        case "lineWidth":
            lineShapeFilteringFilter.radius = lineWidthFromValue(value)
        default: break
        }
    }
}