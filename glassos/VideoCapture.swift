//
//  VideoCapture.swift
//  glassos
//
//  Created by bi119aTe5hXk on 2020/07/23.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import Foundation
import AVFoundation
public protocol VideoCaptureDelegate: class {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CVPixelBuffer?, timestamp: CMTime)
}
public class VideoCapture: NSObject {
    public weak var delegate: VideoCaptureDelegate?
    public var previewLayer: AVCaptureVideoPreviewLayer?
    public var fps = 15
    var lastTimestamp = CMTime()
    
    let videoOutput = AVCaptureVideoDataOutput()
    let captureSession = AVCaptureSession()
    let queue = DispatchQueue(label: "VideoQueue")
    
    let deviceName = "BT-35E"
    
    public func setUp(sessionPreset: AVCaptureSession.Preset = .medium,
                      completion: @escaping (Bool) -> Void) {
      queue.async {
        let success = self.setUpCamera(sessionPreset: sessionPreset)
        DispatchQueue.main.async {
          completion(success)
        }
      }
    }

    func setUpCamera(sessionPreset: AVCaptureSession.Preset) -> Bool{
        captureSession.beginConfiguration()
        captureSession.sessionPreset = sessionPreset
        
        let discoverySession = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [
                    .builtInWideAngleCamera,
                    .externalUnknown
            ],
            mediaType: .video,
            position: .unspecified)



        for device in discoverySession.devices {

            print("cameraID:\(device.localizedName)")
            if device.localizedName == deviceName {
                do {
                    let videoInput = try AVCaptureDeviceInput(device: device)
                    if captureSession.canAddInput(videoInput) {
                        captureSession.addInput(videoInput)
                        
                        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
//                        previewLayer.connection?.videoOrientation = .portrait
                        self.previewLayer = previewLayer


                        let settings: [String: Any] = [
                            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
                        ]
                        videoOutput.videoSettings = settings

                        videoOutput.setSampleBufferDelegate(self, queue: queue)

                        if captureSession.canAddOutput(videoOutput) {
                            captureSession.addOutput(videoOutput)
                        }

                        
                        print("capture session commited")
                        captureSession.commitConfiguration()

                        print("start running capture session")
                        captureSession.startRunning()
                    }
                } catch {
                    // Configuration failed. Handle error.
                    assertionFailure("something is broken...")
                    return false
                }
            }

        }

        return true
    }
    
    public func start() {
      if !captureSession.isRunning {
        captureSession.startRunning()
      }
    }

    public func stop() {
      if captureSession.isRunning {
        captureSession.stopRunning()
      }
    }
}


extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
      // Because lowering the capture device's FPS looks ugly in the preview,
      // we capture at full speed but only call the delegate at its desired
      // framerate.
      let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      let deltaTime = timestamp - lastTimestamp
        if deltaTime >= CMTimeMake(value: 1, timescale: Int32(fps)) {
        lastTimestamp = timestamp
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        delegate?.videoCapture(self, didCaptureVideoFrame: imageBuffer, timestamp: timestamp)
      }
    }

    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
      //print("dropped frame")
    }
//    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {



//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            assertionFailure("failed to convert image buffer")
//            return
//        }



        //let model = YOLOv3()
//        var request: VNRequest
//        do{
//            let model = try VNCoreMLModel(for: YOLOv3().model)
//            request = VNCoreMLRequest(model: model, completionHandler: {
//                (request, err) in
//
////                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
////                    orientation: .up) // fix based on your UI orientation
////                handler.perform([request])
//
//                guard let results = request.results as? [VNClassificationObservation]
//                    else { fatalError("huh") }
//                for classification in results {
//                    print(classification.identifier, // the scene label
//                          classification.confidence)
//
//                    DispatchQueue.main.async {
//                        self.outputText.stringValue = "identifier:\(classification.identifier) \n confidence: \(classification.confidence)"
//                    }
//                }
//            })
//        }catch{
//            assertionFailure("failed to load CoreML model")
//        }




//        let request = VNCoreMLRequest(model: model) { [weak self] (request: VNRequest, error: Error?) in
//            guard let results = request.results as? [VNClassificationObservation] else { return }

        // 判別結果とその確信度を上位3件まで表示
        // identifierは類義語がカンマ区切りで複数書かれていることがあるので、最初の単語のみ取得する
        //let displayText = results.prefix(3).compactMap { "\(Int($0.confidence * 100))% \($0.identifier.components(separatedBy: ", ")[0])" }.joined(separator: "\n")


        //self?.textView.text = displayText
        //print(displayText)
        //self?.outputText.stringValue = displayText
//        }

        // CVPixelBufferに対し、画像認識リクエストを実行
//        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])

//    }
}
