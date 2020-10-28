//
//  DisplayInfo.swift
//  ProjectGOS
//
//  Created by bi119aTe5hXk on 2020/10/28.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import Foundation
import Cocoa

func formatText(string:String) -> [String] {
    //format: ["Display name", "Name of the traffic sign image file"]
    switch string {
    case "Stop":
        return ["止まれ","Stop"]
    case "Slow down":
        
        return ["徐行","Slowdown"]
        
    case "No bicycles":
        return ["自転車走行禁止","Nobicycles"]
        
    case "Traffic mirror":
        return ["交差点注意","Warning"]
        
    case "No entry":
        return ["立ち入り禁止","Noentry"]
        
    default:
        return [string,""]
    }
}

