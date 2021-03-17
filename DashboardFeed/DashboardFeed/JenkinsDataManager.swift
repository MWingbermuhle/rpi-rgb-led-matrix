//
//  JenkinsDataManager.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermuhle on 15/03/2021.
//

import Foundation

class JenkinsDataManager : ObservableObject {
    
    private let appSettings = AppSettings()
    private var timer: Timer? = nil
    
    var listener: JenkinsDataManagerListener? = nil
    
    @Published var jenkinsJobs: [JenkinsJob] = []
    @Published var jobNames: [String] = []
    
    init() {
        if (!appSettings.selectedJob1.isEmpty) {
            jobNames.append(appSettings.selectedJob1)
        }
        if (!appSettings.selectedJob2.isEmpty) {
            jobNames.append(appSettings.selectedJob2)
        }
        if (!appSettings.selectedJob3.isEmpty) {
            jobNames.append(appSettings.selectedJob3)
        }
        if (!appSettings.jenkinsUrl.isEmpty) {
            fetchJenkinsBranches()
        }
    }
    
    func restartIntervalTimer() {
        if (timer != nil) {
            timer?.invalidate()
        }
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(appSettings.intervalSeconds), target: self, selector: #selector(fetchJenkinsBranches), userInfo: nil, repeats: true)
    }
    
    @objc func fetchJenkinsBranches() {
        print("JenkinsDataManager::fetchJenkinsBranches")
        guard let url = URL(string: "\(appSettings.jenkinsUrl)/api/json") else {
            print("Invalid URL")
            // TODO - show error on display
            return
        }
        
        // Start timer
        if (timer == nil) {
            timer = Timer.scheduledTimer(timeInterval: TimeInterval(appSettings.intervalSeconds), target: self, selector: #selector(fetchJenkinsBranches), userInfo: nil, repeats: true)
        }
        
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(JenkinsProject.self, from: data) {
                    // we have good data – go back to the main thread
                    DispatchQueue.main.async {
                        // update our UI
                        self.jenkinsJobs = decodedResponse.jobs
                        self.jobNames = self.jenkinsJobs.map({ (job) -> String in
                            job.name
                        })
                        self.jobNames.insert("", at: 0)
                        self.listener?.onDataUpdate(jobs: self.jenkinsJobs)
                    }

                    // everything is good, so we can exit
                    return
                }
            }

            // if we're still here it means there was a problem
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
        }.resume()
    }
}

protocol JenkinsDataManagerListener {
    func onDataUpdate(jobs: [JenkinsJob])
}

struct JenkinsProject : Codable {
    let name: String
    let jobs: [JenkinsJob]
}

struct JenkinsJob : Codable, Hashable {
    let name: String
    let color: String
}
