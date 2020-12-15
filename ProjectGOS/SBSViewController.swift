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

import CoreBluetooth
let kBLEService_UUID = "79D33887-FB4D-44FF-81F3-9D6B6259CE83"
let kBLE_Characteristic_UUID_0 = "14660535-154C-485B-B3B7-F3F9CFB84D45"
// let kBLE_Characteristic_UUID_1 = "30010C1C-93BF-11D8-8B5B-000A95AF9C6A"

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_UUID_0 = CBUUID(string: kBLE_Characteristic_UUID_0)
// let BLE_Characteristic_UUID_1 = CBUUID(string: kBLE_Characteristic_UUID_1)

class SBSViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    // View point moving distance
    let VPMovingDistance: CGFloat = 1.0

    // Model file name
    let modelName = "JPTrafficSignObjectDetector"

    // Audio device name
//    let audioInName = "BT-35E"
//    let audioOutName = "EPSON HMD"

    var bufferSize: CGSize = .zero

    let userdefault = UserDefaults.standard
    @IBOutlet var leftView: NSView!
    @IBOutlet var rightView: NSView!
    @IBOutlet var leftTextField: NSTextField!
    @IBOutlet var rightTextField: NSTextField!
    @IBOutlet var leftImageView: NSImageView!
    @IBOutlet var rightImageView: NSImageView!

    var currentText: String?
    var currentImageName: String?
    var lastVoice: String?
    var viewResetTimer: Timer? = Timer()
    var movieOutput = AVCaptureMovieFileOutput()
    let synth = NSSpeechSynthesizer()

    var peripheralManager: CBPeripheralManager!

    var peripheral: CBPeripheral!
    var characteristic: CBMutableCharacteristic?

    var strBLETrasnfer = "WELCOM.GOS"
//    var previewIMGData:CGImage!

    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    // MARK: - BLE Peripheral

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
        case .resetting:
            print("Bluetooth Device is RESETTING")
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            addServices()
        @unknown default:
            print("Unknown State")
        }
    }

    func isDeviceConnceting() -> Bool {
        return peripheral.state != .disconnected
    }

    func addServices() {
        // let valueData = "AD34E".data(using: .utf8)
        let char = CBMutableCharacteristic(type: BLE_Characteristic_UUID_0, properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])

        // let char2 = CBMutableCharacteristic(type: BLE_Characteristic_UUID_1, properties: [.read], value: valueData, permissions: [.readable])

        let myService = CBMutableService(type: BLEService_UUID, primary: true)
        myService.characteristics = [char] // ,char2]
        peripheralManager.add(myService)
        startAdvertising()
    }

    func startAdvertising() {
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey: "ProjectGOS", CBAdvertisementDataServiceUUIDsKey: [BLEService_UUID]])
        print("Started Advertising")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to characteristic. \(central.description)")

//        sendDataViaBLE(msg: "subscribed")
    }

//    func sendDataViaBLE(msg:String){
//        print("Sending \(msg) viaBLE")
//        let dataToSend:Data = msg.data(using: String.Encoding.utf8)!
//        guard let peripheral = self.peripheralManager else {
//            return
//        }
//        guard let characteristic = self.characteristic, let centrals = characteristic.subscribedCentrals, !centrals.isEmpty else {
//            return
//        }
//        peripheral.updateValue(dataToSend, for: self.characteristic!, onSubscribedCentrals: nil)
//    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Writing Data:\(requests)")
        if let value = requests.first?.value {
            print(value.hexEncodedString())
            // Perform here your additional operations on the data.
            peripheral.respond(to: requests.first!, withResult: .success)

            doBLEControl(cmd: value.hexEncodedString())
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Data getting Read \(request)")
        request.value = strBLETrasnfer.data(using: .utf8)
        peripheral.respond(to: request, withResult: .success)
    }

    func doBLEControl(cmd: String) {
        switch cmd {
        case "0000ca":
            print("doBLEControl restartApp")
            // recordingVideo()
            restartApp()
            break

        case "0000fa":
            print("doBLEControl Move VP forward")
            viewPointForward(self)
            break

        case "0000ba":
            print("doBLEControl Move VP backward")
            viewPointBackward(self)
            break
            
        case "0000cb":
            print("doBLEControl Move VP reset")
            resetViewPoint(self)
            break
            
//        case "0000cd":
//            print("doBLEControl get cam preview")
//            //print(getPreviewPic())
//            strBLETrasnfer = "PIC.\(getPreviewPic())"
//            break
        
        case "00001e":
            strBLETrasnfer = "VD.StopRecording"
            movieOutput.stopRecording()
            exit(0)
            break

        default:
            return
        }
    }

    func restartApp() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"\(Bundle.main.bundlePath)\""]
        task.launch()

        // self.terminate(nil)
        exit(0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

        let leftP = CGFloat(userdefault.float(forKey: "leftP"))
        let rightP = CGFloat(userdefault.float(forKey: "rightP"))
        setViewObjectPosition(left: leftP, right: rightP)

        showTextOnGlass(string: "Init...\nPlease wait...")
        sleep(1)

        // Set text to voice service to Japanese
        for v in NSSpeechSynthesizer.availableVoices {
            let attrs = NSSpeechSynthesizer.attributes(forVoice: v)
            if attrs[NSSpeechSynthesizer.VoiceAttributeKey(rawValue: "VoiceLanguage")] as? String == "ja-JP" {
                synth.setVoice(v)
                break
            }
        }

        setupAVCapture()
    }

    override func viewDidAppear() {
        view.window?.toggleFullScreen(self)
    }

    override func viewWillDisappear() {
        strBLETrasnfer = "VD.StopRecording"
        movieOutput.stopRecording()
    }

    // MARK: - Video Capture

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        previewIMGData = self.captureImage(sampleBuffer)

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        // video data to VN
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        sendDataViaBLE(msg: "frame dropped")
        print("frame dropped")
    }

    func setupAVCapture() {
        if session.isRunning {
            session.stopRunning()
        }

        var deviceInput: AVCaptureDeviceInput!

        // Select a video device
        let videoDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                // .builtInWideAngleCamera,
                .externalUnknown, // macOS only
            ],
            mediaType: .video,
            position: .unspecified).devices.first

        // Add a audio input
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
            print("Using external camera ID:\(videoDevice?.localizedName)")
            if let vD = videoDevice {
                deviceInput = try AVCaptureDeviceInput(device: vD)
            } else {
                strBLETrasnfer = "ERR.ExternalCameraNOTFound"
                showTextOnGlass(string: "Error\nExternal camera not found!")
                print("Could not create video device input")
                return
            }

        } catch {
            strBLETrasnfer = "ERR.CameraNOTFound"
            showTextOnGlass(string: "Error\nCamera not found!")
            print("Could not create video device input: \(error)")
            return
        }

        session.beginConfiguration()
        // Image size for model is smaller
        session.sessionPreset = .hd1280x720

        // Add a video input
        guard session.canAddInput(deviceInput) else {
            strBLETrasnfer = "ERR.CameraBusy"
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
            strBLETrasnfer = "ERR.CameraBusy"
            showTextOnGlass(string: "Error\nCould not load video data session, is camera busy?")
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)

            // find best format and frame rate
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

            // set frame rate to auto (30fps)
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
        session.startRunning()

        // start video recording
        recordingVideo()
    }

//    func captureImage(_ sampleBuffer:CMSampleBuffer) -> CGImage{
//        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//             let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
//        let context:CIContext = CIContext.init(options: nil)
//             let cgImage:CGImage = context.createCGImage(ciimage, from: ciimage.extent)!
//            return cgImage
//        }
//    func getPreviewPic() -> String {
//        if session.isRunning {
//            //session.take
//            //videoDataOutput.
//            if let picStr = previewIMGData.toString(){
//                return "PIC.\(picStr)"
//            }
//            return ""
//        }
//        return ""
//    }

    // MARK: - Video recording

    func recordingVideo() {
        if movieOutput.isRecording {
            strBLETrasnfer = "VD.isRecording"
            print("video is recording")
            // movieOutput.stopRecording()
        } else {
            strBLETrasnfer = "VD.StartRecording"
            print("start record video")
            let paths = FileManager.default.urls(for: .downloadsDirectory, in: .allDomainsMask)

            let date = Date()
            let components: DateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: date)
            let fileName = "video-\(components.date!).mov"

            let fileUrl = paths[0].appendingPathComponent(fileName)
            print("save path: \(fileUrl)")
            // try? FileManager.default.removeItem(at: fileUrl)
            movieOutput.startRecording(to: fileUrl, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // save video to camera roll
        if error == nil {
            strBLETrasnfer = "VD.VideoSaved"
            print("video saved")
        } else {
            strBLETrasnfer = "ERR.VideoSaveError"
            print("videosave error:\(error)")
            setupAVCapture()
        }
    }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        strBLETrasnfer = "VD.VideoRecording"
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
            resetContent()
            print("reset content from setupVision")
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { request, _ in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue

//                    self.resetContent()
                    if let results = request.results {
                        //                        print("results:\(results)")
                        self.showVisionRequestResults(results)
                    }

                })
            })
            requests = [objectRecognition]
        } catch let error as NSError {
            showTextOnGlass(string: "Error\nLoad AI model error.")
            print("Model loading went wrong: \(error)")
        }

        return error
    }

    func showVisionRequestResults(_ results: [Any]) {
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            //            print("objectObservation:\(objectObservation.labels)")
            let topLabelObservation = objectObservation.labels[0]
            print("Identifier:\(topLabelObservation.identifier), confidence:\(topLabelObservation.confidence)")
            // showText(string: "\(topLabelObservation.identifier)\n\(topLabelObservation.confidence)")

            if topLabelObservation.confidence >= 0.90 {
                let identifier = topLabelObservation.identifier
                self.currentText = ProjectGOS.displayInfo(string: identifier)[0]
                self.currentImageName = ProjectGOS.displayInfo(string: identifier)[1]

                displayInfo()
                textToVoice(voice: ProjectGOS.displayInfo(string: identifier)[2])
            }
//            displayInfo(text: "\(formatText(string: topLabelObservation.identifier)[0])\n\(topLabelObservation.confidence)", image: NSImage(named:formatText(string: topLabelObservation.identifier)[1]))
        }
    }

    func displayInfo() {
        if let text = currentText,
           let imageName = currentImageName,
           self.leftTextField.stringValue != "\n\(currentText)" {
            showTextOnGlass(string: text)
            showImageOnGlass(img: NSImage(named: imageName))

            // sendDataViaBLE(msg: text)
//            strBLETrasnfer = "AI.Found:\(text)"

            // show content for 2s
            viewResetTimer?.invalidate()
            viewResetTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(resetContent), userInfo: nil, repeats: true)
        }
    }

    func textToVoice(voice: String) {
        if voice != lastVoice && !synth.isSpeaking {
            synth.startSpeaking(voice)
            lastVoice = voice
        }
    }

    // MARK: - Side by side UI

    @objc func resetContent() {
        // sendDataViaBLE(msg: "reset view")
        showTextOnGlass(string: "+")
        showImageOnGlass(img: NSImage(named: ""))
        lastVoice = ""
    }

    func showTextOnGlass(string: String) {
        DispatchQueue.main.async {
            self.leftTextField.stringValue = "\n\(string)"
            self.rightTextField.stringValue = "\n\(string)"
        }
    }

    func showImageOnGlass(img: NSImage?) {
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
        let resetLX: CGFloat = 139.0
        let resetRX: CGFloat = 758.0
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

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(count, range.upperBound))
        return String(self[idx1 ..< idx2])
    }
}

// extension CGImage {
//    func toString() -> String? {
//        let bmpImgRef = NSBitmapImageRep(cgImage: self)
//        let data = bmpImgRef.representation(using: .png, properties: [:])
//        return data?.base64EncodedString(options: .endLineWithLineFeed)
//    }
// }
