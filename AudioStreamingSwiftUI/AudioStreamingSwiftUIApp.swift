//
//  AudioStreamingSwiftUIApp.swift
//  AudioStreamingSwiftUI
//
//  Created by Fachri Febrian on 26/02/2025.
//

import SDWebImageSVGCoder
import SDWebImageSwiftUI
import SwiftUI

@main
struct AudioStreamingSwiftUIApp: App {
    
    init() {
        let svgCoder = SDImageSVGCoder.shared
        SDImageCodersManager.shared.addCoder(svgCoder)
    }
    
    var body: some Scene {
        WindowGroup {
            GreetingsPage()
        }
    }
}
