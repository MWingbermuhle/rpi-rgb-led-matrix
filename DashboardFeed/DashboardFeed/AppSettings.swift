//
//  AppSettings.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermuhle on 15/03/2021.
//

import Foundation

class AppSettings : ObservableObject {
    enum StorageKeys : String {
        case jenkinsUrl = "DashboardJenkinsUrl"
        case job1name = "DashboardJenkinsJob1Name"
        case job2name = "DashboardJenkinsJob2Name"
        case job3name = "DashboardJenkinsJob3Name"
        case intervalSeconds = "DashboardJenkinsIntervalSeconds"
    }
    
    @Published var jenkinsUrl: String {
        didSet {
            UserDefaults.standard.set(jenkinsUrl, forKey: StorageKeys.jenkinsUrl.rawValue)
        }
    }
    
    @Published var selectedJob1: String {
        didSet {
            UserDefaults.standard.set(selectedJob1, forKey: StorageKeys.job1name.rawValue)
        }
    }
    @Published var selectedJob2: String {
        didSet {
            UserDefaults.standard.set(selectedJob2, forKey: StorageKeys.job2name.rawValue)
        }
    }
    @Published var selectedJob3: String {
        didSet {
            UserDefaults.standard.set(selectedJob3, forKey: StorageKeys.job3name.rawValue)
        }
    }
    @Published var intervalSeconds: Int {
        didSet {
            UserDefaults.standard.set(intervalSeconds, forKey: StorageKeys.intervalSeconds.rawValue)
        }
    }
    
    
    init() {
        jenkinsUrl = UserDefaults.standard.string(forKey: StorageKeys.jenkinsUrl.rawValue) ?? ""
        selectedJob1 = UserDefaults.standard.string(forKey: StorageKeys.job1name.rawValue) ?? ""
        selectedJob2 = UserDefaults.standard.string(forKey: StorageKeys.job2name.rawValue) ?? ""
        selectedJob3 = UserDefaults.standard.string(forKey: StorageKeys.job3name.rawValue) ?? ""
        let interval = UserDefaults.standard.integer(forKey: StorageKeys.intervalSeconds.rawValue)
        if (interval == 0) {
            // use default of 60 seconds
            intervalSeconds = 60
        } else {
            intervalSeconds = interval
        }
    }
}
