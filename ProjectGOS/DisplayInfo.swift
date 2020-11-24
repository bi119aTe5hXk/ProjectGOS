//
//  DisplayInfo.swift
//  ProjectGOS
//
//  Created by bi119aTe5hXk on 2020/10/28.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import Foundation
import Cocoa

func displayInfo(string:String) -> [String] {
    //format: ["Display name", "Name of the traffic sign image file","TTS text"]
    switch string {
    case "Stop":
        return ["止まれ","Stop","止まってください"]
    case "Slow down":
        
        return ["徐行注意","Slowdown","徐行です"]
        
    case "No bicycles":
        return ["自転車走行禁止","Nobicycles","走行禁止です"]
        
    case "Traffic mirror":
        return ["交差点注意","Warning","交差点です"]
        
    case "No entry":
        return ["立ち入り禁止","Noentry","止まってください"]
        
    default:
        return [string,"",""]
    }
}

