//
//  ContentView.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermühle on 13/03/2021.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var mqttClient = MqttClient()
    @ObservedObject var appSettings = AppSettings()
    @ObservedObject var jenkinsDataManager = JenkinsDataManager()
    
    let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter
        }()
    
    var body: some View {
        VStack {
            HStack {
                Text("Mqtt connection: ")
                mqttClient.isConnected ? Text("online") : Text("offline")
            }.padding(.horizontal, 10)
            Divider()
            Text("Jenkins Settings").padding(.horizontal, 10)
            HStack {
                Text("URL: ")
                TextField("Enter Jenkins URL...", text: $appSettings.jenkinsUrl)
                Button(action: { jenkinsDataManager.fetchJenkinsBranches() }, label: {
                    Text("Fetch")
                })
            }.padding(.horizontal, 10)
            HStack {
                Text("Interval (seconds): ")
                TextField("Enter interval in seconds...", value: $appSettings.intervalSeconds, formatter: numberFormatter)
                Button(action: { jenkinsDataManager.restartIntervalTimer() }, label: {
                    Text("Restart")
                })
            }.padding(.horizontal, 10)
            
            Divider()
            Text("Branch configurations").padding(.horizontal, 10)
            Form {
                Section {
                    Picker("Branch 1: ", selection: $appSettings.selectedJob1.onChange(selectedJob1Changed)) {
                        ForEach(jenkinsDataManager.jobNames, id: \.self) {
                            Text($0)
                        }
                    }
                    Picker("Branch 2: ", selection: $appSettings.selectedJob2.onChange(selectedJob2Changed)) {
                        ForEach(jenkinsDataManager.jobNames, id: \.self) {
                            Text($0)
                        }
                    }
                    Picker("Branch 3: ", selection: $appSettings.selectedJob3.onChange(selectedJob3Changed)) {
                        ForEach(jenkinsDataManager.jobNames, id: \.self) {
                            Text($0)
                        }
                    }
                }
                .disabled(jenkinsDataManager.jenkinsJobs.isEmpty)
            }.padding(.horizontal, 10)
            
            Button(action: { NSApp.terminate(nil) }, label: {
                Text("Quit")
            })
        }
    }
    
    func selectedJob1Changed(_ jobName: String) {
        if (jobName.isEmpty) {
            mqttClient.sendBranchUpdate(index: 0, name: "", status: "")
        }
        self.jenkinsDataManager.fetchJenkinsBranches()
    }
    
    func selectedJob2Changed(_ jobName: String) {
        if (jobName.isEmpty) {
            mqttClient.sendBranchUpdate(index: 1, name: "", status: "")
        }
        self.jenkinsDataManager.fetchJenkinsBranches()
    }
    
    func selectedJob3Changed(_ jobName: String) {
        if (jobName.isEmpty) {
            mqttClient.sendBranchUpdate(index: 2, name: "", status: "")
        }
        self.jenkinsDataManager.fetchJenkinsBranches()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}
