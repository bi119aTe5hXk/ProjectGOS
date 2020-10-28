//
//  AIHandler.swift
//  ProjectGOS
//
//  Created by bi119aTe5hXk on 2020/10/28.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//
import AVFoundation
import Foundation
import Vision
import Cocoa
import CoreMedia
import VideoToolbox

class AIHandler:NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //Model file name
    let modelName = "JPTrafficSignObjectDetector"
    var bufferSize: CGSize = .zero

    private let session = AVCaptureSession()
    //private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()

    // MARK: - Video Capture
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    func startCaptureSession() {
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         print("frame dropped")
    }

    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [
                    //.builtInWideAngleCamera,
                    .externalUnknown
            ],
            mediaType: .video,
            position: .unspecified).devices.first
        
        do {
            showText(string: "Loading Camera...\nPlease wait...")
            print("Using external camera ID:\(videoDevice!.localizedName)")
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            showText(string: "Error\nCamera not found!")
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            showText(string: "Error\nCould not load video device, is it busy?")
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            showText(string: "Error\nCould not load video data session, is camera busy?")
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }


    // MARK: - AI Object Recognition & Display


    // Vision parts
    private var requests = [VNRequest]()

    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        showText(string: "Loading AI model...\nPlease wait...")
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                showText(string: "+")
//                self.showImageOnGlass(img:NSImage(named:""))
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
    //                        self.drawVisionRequestResults(results)
                        
    //                        print("results:\(results)")
                        self.showVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            showText(string: "Error\nLoad AI model error.")
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }

    func showVisionRequestResults(_ results: [Any]) {
        for observation in results where observation is VNRecognizedObjectObservation{
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
    //            print("objectObservation:\(objectObservation.labels)")
            
            let topLabelObservation = objectObservation.labels[0]
            print("Identifier:\(topLabelObservation.identifier), confidence:\(topLabelObservation.confidence)")
            //showText(string: "\(topLabelObservation.identifier)\n\(topLabelObservation.confidence)")
            showText(string: "\(topLabelObservation.identifier)")
        }
    }
    
}


