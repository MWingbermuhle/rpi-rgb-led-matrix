//
//  ContentView.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermühle on 13/03/2021.
//

import SwiftUI

struct ContentView: View {
    
    @State var isConnected = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Mqtt connection: ")
                self.isConnected ? Text("online") : Text("offline")
            }
            Button(action: { fetchJenkinsBranches() }, label: {
                Text("Fetch Jenkins Branches")
            })
            HStack {
                Text("Branch 1: ")
                
            }
            Button(action: { NSApp.terminate(nil) }, label: {
                Text("Quit")
            })
        }
    }
    
    func fetchJenkinsBranches() { }
}

extension ContentView : MqttClientListener {
    func connected() {
        isConnected = true
    }
    
    func disconnected() {
        isConnected = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
