//
//  DisplayInfo.swift
//  ProjectGOS
//
//  Created by bi119aTe5hXk on 2020/10/28.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import Foundation
import Cocoa

func formatText(string:String) -> String {
    switch string {
    
    case "Stop":
        return "止まれ"
    case "Slow down":
        return "徐行"
        
    case "No bicycles":
        return "自転車走行禁止"
        
    case "Traffic mirror":
        return "交差点注意"
        
        
        
    default:
        return string
    }
}

