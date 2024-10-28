//
//  CoChatView.swift
//  WorkFlow
//
//  Created by Jason Rincon on 10/27/24.
//

import Foundation
import SwiftUI

// ChatView represents the chat interface.
struct CoChatView: View {
    var body: some View {
        ZStack {
            // Background gradient for the view.
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // Placeholder text for the chat view.
            Text("Contractor Chat View")
                .navigationBarTitle("Chat", displayMode: .inline)
        }
    }
}

// Preview for ChatView to visualize the view in Xcode's canvas.
struct CoChatView_Previews: PreviewProvider {
    static var previews: some View {
        CoChatView()
            .environmentObject(JobController())
            .environmentObject(ContractorController())
    }
}

