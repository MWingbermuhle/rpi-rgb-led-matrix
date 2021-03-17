//
//  DashboardFeeder.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermuhle on 17/03/2021.
//

import Foundation

class DashboardFeeder : JenkinsDataManagerListener {
    
    private let mqttClient: MqttClient
    private let jenkinsDataManager: JenkinsDataManager
    private let appSettings: AppSettings
    
    init(mqttClient: MqttClient, jenkinsDataManager: JenkinsDataManager, appSettings: AppSettings) {
        self.mqttClient = mqttClient
        self.jenkinsDataManager = jenkinsDataManager
        self.appSettings = appSettings
        self.jenkinsDataManager.listener = self
    }
    
    func onDataUpdate(jobs: [JenkinsJob]) {
        print("DashboardFeeder::onDataUpdate called")
        if (!appSettings.selectedJob1.isEmpty) {
            let optionalJob = jobs.first { (job) -> Bool in
                appSettings.selectedJob1 == job.name
            }
            if let job = optionalJob {
                mqttClient.sendBranchUpdate(index: 0, name: job.name, status: translateColor(job.color))
            }
        }
        if (!appSettings.selectedJob2.isEmpty) {
            let optionalJob = jobs.first { (job) -> Bool in
                appSettings.selectedJob2 == job.name
            }
            if let job = optionalJob {
                mqttClient.sendBranchUpdate(index: 1, name: job.name, status: translateColor(job.color))
            }
        }
        if (!appSettings.selectedJob3.isEmpty) {
            let optionalJob = jobs.first { (job) -> Bool in
                appSettings.selectedJob3 == job.name
            }
            if let job = optionalJob {
                mqttClient.sendBranchUpdate(index: 2, name: job.name, status: translateColor(job.color))
            }
        }
    }
    
    func translateColor(_ color: String) -> String {
        switch color {
        // blue
        case "blue":
            return "green"
        case "blue_anime":
            return "green"
        // not built
        case "notbuilt":
            return "grey"
        case "notbuilt_anime":
            return "grey"
        // disabled
        case "disabled":
            return "grey"
        case "disabled_anime":
            return "grey"
        // green
        case "green":
            return "green"
        case "green_anime":
            return "green"
        // red
        case "red":
            return "red"
        case "red_anime":
            return "red"
        // yellow
        case "yellow":
            return "orange"
        case "yellow_anime":
            return "orange"
        // aborted
        case "aborted":
            return "grey"
        case "aborted_anime":
            return "grey"
        // grey
        case "grey":
            return "grey"
        case "grey_anime":
            return "grey"
        
        default:
            print("Warning: Unrecognized color: \(color)")
            return color
        }
    }
}
