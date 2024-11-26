import SwiftUI

struct  FireworksEffect: View {
    @State private var showFireworks1 = false
    @State private var showFireworks2 = false
    @State private var showFireworks3 = false

    var body: some View {
            ZStack {
                if #available(iOS 15.0, *) {
                ZStack {
                    VStack(spacing: 100) {
                        Image("fireworks1")
                            .scaleEffect(showFireworks1 ? 1.5 : 0)
                            .opacity(showFireworks1 ? 0 : 1)
                            .hueRotation(.degrees(showFireworks1 ? 45 : 0))
                            .rotationEffect(.degrees(showFireworks1 ? 30 : -30), anchor: .center)
                        
                        Image("fireworks2")
                            .scaleEffect(showFireworks2 ? 2 : 0)
                            .opacity(showFireworks2 ? 0 : 1)
                            .hueRotation(.degrees(showFireworks2 ? 50 : 0))
                            .rotationEffect(.degrees(showFireworks2 ? -45 : 45), anchor: .center)
                        
                        Image("fireworks3")
                            .scaleEffect(showFireworks3 ? 1.5 : 0)
                            .opacity(showFireworks3 ? 0 : 1)
                            .hueRotation(.degrees(showFireworks3 ? 45 : 0))
                            .rotationEffect(.degrees(showFireworks3 ? 30 : -30), anchor: .center)
                    }
                    
                    HStack {
                        Image("fireworks1")
                            .scaleEffect(showFireworks1 ? 1 : 0)
                            .opacity(showFireworks1 ? 0 : 1)
                            .rotationEffect(.degrees(showFireworks1 ? -30 : 30), anchor: .center)
                        
                        Image("fireworks2")
                            .scaleEffect(showFireworks2 ? 1 : 0)
                            .opacity(showFireworks2 ? 0 : 1)
                            .rotationEffect(.degrees(showFireworks2 ? 30 : -30), anchor: .center)
                        Image("fireworks3")
                            .scaleEffect(showFireworks3 ? 1 : 0)
                            .opacity(showFireworks3 ? 0 : 1)
                            .rotationEffect(.degrees(showFireworks3 ? -30 : 30), anchor: .center)
                    }
                }
                .task {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        showFireworks1.toggle()
                    }
                    
                    withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        showFireworks2.toggle()
                    }
                    
                    withAnimation(.easeIn(duration: 2.15).repeatForever(autoreverses: false)) {
                        showFireworks3.toggle()
                    }
                    
            }
                } else {
                    // Fallback on earlier versions
                }
                
                HStack {
                    Spacer()
                    Text("")
                        .font(.caption)
                    .textCase(.uppercase)
                }
                .frame(width: 340)
            } // All views
    }
}

struct  FireworksEffect_Previews: PreviewProvider {
    static var previews: some View {
        FireworksEffect()
            .preferredColorScheme(.dark)
    }
}
