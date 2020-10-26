//
//  ViewController.swift
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

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    /* Settings */
    //Model file name
    let modelName = "JPTrafficSignObjectDetector"
    //View point moving distance
    let VPMovingDistance: CGFloat = 1.0
    
    
    let userdefault = UserDefaults.standard
    @IBOutlet var leftView:NSView!
    @IBOutlet var rightView:NSView!
    @IBOutlet var leftTextField: NSTextField!
    @IBOutlet var rightTextField: NSTextField!
    @IBOutlet var leftImageView: NSImageView!
    @IBOutlet var rightImageView: NSImageView!
    
    
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    private let session = AVCaptureSession()
    //private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let leftP = CGFloat(userdefault.float(forKey: "leftP"))
        let rightP = CGFloat(userdefault.float(forKey: "rightP"))
        setViewObjectPosition(left: leftP, right: rightP)
        
        showTextOnGlass(string: "Init...\nPlease wait...")
        
        
        setupAVCapture()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    
    // MARK: - Video Capture
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func startCaptureSession() {
        session.startRunning()
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
            showTextOnGlass(string: "Loading Camera...\nPlease wait...")
            print("Using external camera ID:\(videoDevice!.localizedName)")
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            showTextOnGlass(string: "Error\nCamera not found!")
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            showTextOnGlass(string: "Error\nCould not load video device, is it busy?")
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
        showTextOnGlass(string: "Loading AI model...\nPlease wait...")
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                self.showTextOnGlass(string: "+")
                self.showImageOnGlass(img:NSImage(named:""))
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
            showTextOnGlass(string: "\(topLabelObservation.identifier)\n\(topLabelObservation.confidence)")
        }
    }
    
    // MARK: - Side by side UI
    func showTextOnGlass(string:String){
        DispatchQueue.main.async {
            self.leftTextField.stringValue = string
            self.rightTextField.stringValue = string
        }
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
