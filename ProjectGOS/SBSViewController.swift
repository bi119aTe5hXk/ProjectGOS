//
//  SBSViewController.swift
//  ProjectGOS
//
//  Created by billgateshxk on 2020/07/22.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import AVFoundation
import Cocoa
import CoreMedia
import VideoToolbox
import Vision

class SBSViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // save video to camera roll
        if error == nil {
            print("video saved")
        }else{
            print(error)
        }

    }
    
    //View point moving distance
    let VPMovingDistance: CGFloat = 1.0
    
    //Model file name
    let modelName = "JPTrafficSignObjectDetector"
    
    //Audio device name
//    let audioInName = "BT-35E"
//    let audioOutName = "EPSON HMD"
    
    var bufferSize: CGSize = .zero
    
    let userdefault = UserDefaults.standard
    @IBOutlet weak var leftView:NSView!
    @IBOutlet weak var rightView:NSView!
    @IBOutlet weak var leftTextField: NSTextField!
    @IBOutlet weak var rightTextField: NSTextField!
    @IBOutlet weak var leftImageView: NSImageView!
    @IBOutlet weak var rightImageView: NSImageView!
    
    var currentText: String?
    var currentImageName: String?
    var viewResetTimer:Timer? = Timer.init()
    var movieOutput = AVCaptureMovieFileOutput()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftP = CGFloat(userdefault.float(forKey: "leftP"))
        let rightP = CGFloat(userdefault.float(forKey: "rightP"))
        setViewObjectPosition(left: leftP, right: rightP)
        
        showTextOnGlass(string: "Init...\nPlease wait...")
        sleep(1)
        
        setupAVCapture()
        
    }
    override func viewDidAppear() {
        view.window?.toggleFullScreen(self)
    }
    
    override func viewWillDisappear() {
        movieOutput.stopRecording()
    }
    
    

    private let session = AVCaptureSession()
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
        //video data to VN
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
        
        // Select a video device
        let videoDevice = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [
                    //.builtInWideAngleCamera,
                    .externalUnknown //macOS only
            ],
            mediaType: .video,
            position: .unspecified).devices.first
        
        //Add a audio input
//        let audioInput = AVCaptureDevice.DiscoverySession.init(
//            deviceTypes: [
//
//                    .externalUnknown //macOS only
//            ],
//            mediaType: nil,
//            position: .unspecified).devices
//        for device in audioInput {
//            print("found audo devices:\(device.description)")
//            if device.description == audioInName{
//                //mic
//                print("Device Mic found!")
//            }
//            if device.description == audioOutName{
//                //headphone
//                print("Device Headphone found!")
//            }
//        }
        
        do {
            showTextOnGlass(string: "Loading Camera...\nPlease wait...")
            print("Using external camera ID:\(videoDevice!.localizedName)")
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            showTextOnGlass(string: "Error\nCamera not found!")
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        //Image size for model is smaller
        session.sessionPreset = .hd1280x720
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            showTextOnGlass(string: "Error\nCould not load video device, is it busy?")
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        
        if session.canAddOutput(videoDataOutput) {
            // Add a video data output for video recording
            session.addOutput(movieOutput)
            // Add a video data output to VN
            session.addOutput(videoDataOutput)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            showTextOnGlass(string: "Error\nCould not load video data session, is camera busy?")
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
            
            //find best format and frame rate
//            var bestFormat: AVCaptureDevice.Format? = nil
//                var bestFrameRateRange: AVFrameRateRange? = nil
//            for formatf in videoDevice!.formats {
//                let format = formatf
//                    print(format)
//                    for rangef in format.videoSupportedFrameRateRanges {
//                        let range = rangef
//                        print(range)
//                        if (bestFrameRateRange == nil) {
//                            bestFormat = format
//                            bestFrameRateRange = range
//                        } else if range.maxFrameRate > bestFrameRateRange!.maxFrameRate {
//                            bestFormat = format
//                            bestFrameRateRange = range
//                        }
//                    }
//                }
//            print("bestFormat:\(bestFormat),bestFrameRateRange:\(bestFrameRateRange)")
            
                //set frame rate to auto (30fps)
            for vFormat in videoDevice!.formats {
                var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
                var frameRates = ranges[0]
                videoDevice!.activeFormat = vFormat as AVCaptureDevice.Format
                videoDevice!.activeVideoMinFrameDuration = frameRates.minFrameDuration
                videoDevice!.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
            }

            
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        setupVision()
        
        // Start the capture
        startCaptureSession()
        
        //start video recording
        recordingVideo()
    }
    // MARK: - Video recording
    func recordingVideo() {
        if movieOutput.isRecording {
            print("video is recording")
        //movieOutput.stopRecording()
        } else {
            print("start record video")
            let paths = FileManager.default.urls(for: .downloadsDirectory, in: .allDomainsMask)
            
            let date = Date()
            let components:DateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: date)
            let fileName = "video-\(components.date!).mov"
            
            let fileUrl = paths[0].appendingPathComponent(fileName)
            print("save path: \(fileUrl)")
        //try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
    }

    // MARK: - AI Object Recognition & Display
    
    // Vision parts
    private var requests = [VNRequest]()

    @discardableResult
    func setupVision() -> NSError? {
        let error: NSError! = nil
        showTextOnGlass(string: "Loading AI model...\nPlease wait...")
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            self.resetContent()
            print("reset content from setupVision")
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    
//                    self.resetContent()
                    if let results = request.results {
    //                        print("results:\(results)")
                        self.showVisionRequestResults(results)
                    }
                    
                    
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            showTextOnGlass(string: "Error\nLoad AI model error.")
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

            if (topLabelObservation.confidence >= 0.95) {
                self.currentText = "\(formatText(string: topLabelObservation.identifier)[0])"
                self.currentImageName = formatText(string: topLabelObservation.identifier)[1]
                displayInfo()
            }
//            displayInfo(text: "\(formatText(string: topLabelObservation.identifier)[0])\n\(topLabelObservation.confidence)", image: NSImage(named:formatText(string: topLabelObservation.identifier)[1]))
            

        }
    }
    
    func displayInfo() {
        if let text = self.currentText,
           let imageName = self.currentImageName,
           self.leftTextField.stringValue != "\n\(self.currentText)" {
            self.showTextOnGlass(string: text)
            self.showImageOnGlass(img: NSImage(named:imageName))
            
            //show content for 2s
            self.viewResetTimer?.invalidate()
            self.viewResetTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.resetContent), userInfo: nil, repeats: true)
        }
    }
    
    // MARK: - Side by side UI
    func showTextOnGlass(string:String){
        DispatchQueue.main.async {
            self.leftTextField.stringValue = "\n\(string)"
            self.rightTextField.stringValue = "\n\(string)"
        }
    }
    @objc func resetContent(){
        self.showTextOnGlass(string: "+")
        self.showImageOnGlass(img:NSImage(named:""))
        
        
    }
    func showImageOnGlass(img:NSImage?){
        DispatchQueue.main.async {
            self.leftImageView.image = img
            self.rightImageView.image = img
        }
    }
    func setViewObjectPosition(left: CGFloat, right: CGFloat) {
        let leftV = leftView.frame
        let rightV = rightView.frame
        leftView.frame = CGRect(x: left,
                                     y: leftV.origin.y,
                                     width: leftV.size.width,
                                     height: leftV.size.height)

        rightView.frame = CGRect(x: right,
                                      y: rightV.origin.y,
                                      width: rightV.size.width,
                                      height: rightV.size.height)
    }

    @IBAction func viewPointForward(_ sender: Any) {
//        print("moving view point forward...")
        let leftV = leftView.frame
        let rightV = rightView.frame
        leftView.frame = CGRect(x: leftV.origin.x - VPMovingDistance,
                                     y: leftV.origin.y,
                                     width: leftV.size.width,
                                     height: leftV.size.height)

        rightView.frame = CGRect(x: rightV.origin.x + VPMovingDistance,
                                      y: rightV.origin.y,
                                      width: rightV.size.width,
                                      height: rightV.size.height)

        saveViewObjectPostiton(left: leftView.frame.origin.x,
                               right: rightView.frame.origin.x)
    }

    @IBAction func viewPointBackward(_ sender: Any) {
//        print("moving view point backward...")
        let leftV = leftView.frame
        let rightV = rightView.frame
        leftView.frame = CGRect(x: leftV.origin.x + VPMovingDistance,
                                     y: leftV.origin.y,
                                     width: leftV.size.width,
                                     height: leftV.size.height)

        rightView.frame = CGRect(x: rightV.origin.x - VPMovingDistance,
                                      y: rightV.origin.y,
                                      width: rightV.size.width,
                                      height: rightV.size.height)

        saveViewObjectPostiton(left: leftView.frame.origin.x,
                               right: rightView.frame.origin.x)
    }

    @IBAction func resetViewPoint(_ sender: Any) {
        let resetLX:CGFloat = 139.0
        let resetRX:CGFloat = 758.0
        let leftV = leftView.frame
        let rightV = rightView.frame
        leftView.frame = CGRect(x: resetLX,
                                     y: leftV.origin.y,
                                     width: leftV.size.width,
                                     height: leftV.size.height)

        rightView.frame = CGRect(x: resetRX,
                                      y: rightV.origin.y,
                                      width: rightV.size.width,
                                      height: rightV.size.height)
    }

    func saveViewObjectPostiton(left: CGFloat, right: CGFloat) {
        userdefault.setValue(Float(left), forKey: "leftP")
        userdefault.setValue(Float(right), forKey: "rightP")
        userdefault.synchronize()
    }
    

}
