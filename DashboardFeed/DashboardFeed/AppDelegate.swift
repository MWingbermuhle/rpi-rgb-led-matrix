//
//  AppDelegate.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermühle on 13/03/2021.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var contentView: ContentView!
    private var dashboardFeeder: DashboardFeeder? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        contentView = ContentView()

        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "Icon")
            button.action = #selector(togglePopover(_:))
            
        }
        
        print("applicationDidFinishLaunching: Start MQTT Client")
        contentView.mqttClient.listener = self
        contentView.mqttClient.connect()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        contentView.mqttClient.disconnect()
    }
    
    // Create the status item
    @objc func togglePopover(_ sender: AnyObject?) {
         if let button = self.statusBarItem.button {
              if self.popover.isShown {
                   self.popover.performClose(sender)
              } else {
                   self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
              }
         }
    }
}

extension AppDelegate: MqttClientListener {
    func connected() {
        print("AppDelegate::MQTTClientListener::disconnected")
        self.dashboardFeeder = DashboardFeeder(mqttClient: contentView.mqttClient, jenkinsDataManager: contentView.jenkinsDataManager, appSettings: contentView.appSettings)
    }
    
    func disconnected() {
        print("AppDelegate::MQTTClientListener::disconnected")
    }
    
    
}
