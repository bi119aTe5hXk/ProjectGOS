//
//  ViewController.swift
//  glassos
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
    
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
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
            print("Using external camera ID:\(videoDevice!.localizedName)")
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
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
        //previewLayer = AVCaptureVideoPreviewLayer(session: session)
        //previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //previewLayer.frame = rootLayer.bounds
//        rootLayer.addSublayer(previewLayer)
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    // Clean up capture setup
    func teardownAVCapture() {
//        previewLayer.removeFromSuperlayer()
//        previewLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("frame dropped")
    }
    
    
    
    
    // MARK: - Side by side UI
    func showTextOnGlass(string:String){
        leftTextField.stringValue = string
        rightTextField.stringValue = string
    }
    func showImageOnGlass(img:NSImage){
        leftImageView.image = img
        rightImageView.image = img
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
    
    
    // MARK: - AI Object Recognition
    
    
    private var detectionOverlay: CALayer! = nil
    
    // Vision parts
    private var requests = [VNRequest]()
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        guard let modelURL = Bundle.main.url(forResource: "JPTrafficSignObjectDetector", withExtension: "mlmodelc") else {
            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                print("Model loaded.")
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
//                        self.drawVisionRequestResults(results)
                        
                        //print("results:\(results.)")
                        self.showVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
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
            let topLabelObservation = objectObservation.labels[0]
            print("Identifier:\(topLabelObservation.identifier), confidence:\(topLabelObservation.confidence)")
        }
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = NSFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}
