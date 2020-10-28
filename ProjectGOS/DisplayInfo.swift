//
//  DisplayInfo.swift
//  ProjectGOS
//
//  Created by bi119aTe5hXk on 2020/10/28.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import Foundation
import Cocoa

func showText(string:String) {
    let sbs = SBSViewController()
    var showStr = string
    
    switch string {
    
    case "Stop":
        showStr = "止まれ"
    case "Slow down":
        showStr = "徐行"
        
    case "No bicycles":
        showStr = "自転車走行禁止"
        
    case "Traffic mirror":
        showStr = "交差点注意"
        
        
        
    default:
        showStr = string
    }
    sbs.showTextOnGlass(string: showStr)
}
func showImage(img:NSImage){
    let sbs = SBSViewController()
    sbs.showImageOnGlass(img: img)
}
