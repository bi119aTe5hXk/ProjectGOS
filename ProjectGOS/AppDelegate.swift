//
//  AppDelegate.swift
//  ProjectGOS
//
//  Created by billgateshxk on 2020/07/22.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let userdefault = UserDefaults.standard
        userdefault.register(defaults: ["leftP" : 139.0])
        userdefault.register(defaults: ["rightP" : 758.0])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

