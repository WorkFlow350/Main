import Foundation
import SwiftUI

struct ChatView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#a3d3eb"), Color(hex: "#355c7d")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) 
                Text("Chat View")
                    .navigationBarTitle("Chat", displayMode: .inline)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView().environmentObject(JobController()).environmentObject(ContractorController())
    }
}

