//
//  ContentView.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermühle on 06/02/2021.
//

import SwiftUI

struct ContentView: View {
    var dashboard = DashboardCanvas()
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()

            Image(nsImage: startDrawing())

            Button(action: { saveImage() }) {
                Text("Save Image")
            }

        }
    }
    
    func startDrawing() -> NSImage {
        dashboard.drawBranchStatus(status: .success, name: "develop")
        dashboard.drawBranchStatus(status: .failed, name: "feature/refactor-commlib")
        dashboard.drawBranchStatus(status: .unstable, name: "bugfix/mjolnir-demoapp")
        dashboard.drawBranchStatus(status: .success, name: "release/2003.3")
        
        return dashboard.toImage()
    }
    
    func saveImage() {
        dashboard.save()
    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
