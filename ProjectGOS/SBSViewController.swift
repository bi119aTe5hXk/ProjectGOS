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

class SBSViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    //View point moving distance
    let VPMovingDistance: CGFloat = 1.0
    
    
    let userdefault = UserDefaults.standard
    @IBOutlet var leftView:NSView!
    @IBOutlet var rightView:NSView!
    @IBOutlet var leftTextField: NSTextField!
    @IBOutlet var rightTextField: NSTextField!
    @IBOutlet var leftImageView: NSImageView!
    @IBOutlet var rightImageView: NSImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let leftP = CGFloat(userdefault.float(forKey: "leftP"))
        let rightP = CGFloat(userdefault.float(forKey: "rightP"))
        setViewObjectPosition(left: leftP, right: rightP)
        
        showTextOnGlass(string: "Init...\nPlease wait...")
        
        let ai = AIHandler()
        ai.setupAVCapture()
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
