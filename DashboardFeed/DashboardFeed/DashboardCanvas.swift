//
//  DashboardCanvas.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermühle on 06/02/2021.
//

import Foundation
import SwiftUI

class DashboardCanvas {
    
    enum BranchStatus {
        case failed
        case success
        case unstable
    }
    
    private var bitmap = BitmapCanvas(128, 64, NSColor.black)
    private var lineCount = 0;
    
    
    func drawBranchStatus(status: BranchStatus, name: String) {
        let lineOffset = lineCount * 12
        
        var statusColor: NSColor
        switch status {
        case .success:
            statusColor = NSColor.green
        case .failed:
            statusColor = NSColor.red
        case .unstable:
            statusColor = NSColor.orange
        }
        
        var textColor: NSColor = NSColor.white
        var text = name
        if name.starts(with: "feature/") {
            textColor = NSColor.cyan
            text = name.replacingOccurrences(of: "feature/", with: "")
        }
        if name.starts(with: "bugfix/") {
            textColor = NSColor.magenta
            text = name.replacingOccurrences(of: "bugfix/", with: "")
        }
        if name.starts(with: "release/") {
            textColor = NSColor.blue
            text = name.replacingOccurrences(of: "release/", with: "")
        }
        
        bitmap.ellipse(NSRect(x: 2, y: 2 + lineOffset, width: 8, height: 8), stroke: statusColor, fill: statusColor)
        bitmap.text(text, NSPoint(x: 14, y: 4 + lineOffset), color: textColor)
        
        lineCount += 1
    }
    
    func toImage() -> NSImage {
        let image = NSImage(size: NSSize(width: bitmap.width, height: bitmap.height))
        image.addRepresentation(bitmap.bitmapImageRep)
        return image
    }
    
    func clear() {
        bitmap.fill(NSPoint(x: 0, y: 0),color: NSColor.black)
    }
    
    func save() {
        let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
        let url = dir.appendingPathComponent("dashboard.ppm")
        
        do {
            let header = "P6 \n\(Int(bitmap.width)) \(Int(bitmap.height)) \n255 \n"
            guard let headerData = header.data(using: String.Encoding.ascii) else {
                print("Header cannot be serialized")
                return
            }
            
            let pixelCount: Int = Int(bitmap.width) * Int(bitmap.height)
            guard let bitmapData = bitmap.bitmapImageRep.bitmapData else {
                print("Could not get bitmap data")
                return
            }
            var intArray: [UInt8] = Array()
            for i in 0...(pixelCount) {
                intArray.append(bitmapData[i*4])
                intArray.append(bitmapData[(i*4)+1])
                intArray.append(bitmapData[(i*4)+2])
            }
            
            var data = headerData
            data.append(Data(intArray))
            
            if let fileHandle = FileHandle(forWritingAtPath: url.path) {
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.write(data)
            }
            else {
                try data.write(to: url, options: .atomic)
            }
            
        } catch {
            print("Could not save to file \(url)")
        }
        
        print("Saved dashboard to file \(url)")
    }
    
    private func documentDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                    .userDomainMask,
                                                                    true)
        return documentDirectory[0]
    }
    
    
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
         try (self + "\n").appendToURL(fileURL: fileURL)
     }

     func appendToURL(fileURL: URL) throws {
         let data = self.data(using: String.Encoding.ascii)!
         try data.append(fileURL: fileURL)
     }
 }

 extension Data {
     func append(fileURL: URL) throws {
         if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(self)
         }
         else {
             try write(to: fileURL, options: .atomic)
         }
     }
 }
