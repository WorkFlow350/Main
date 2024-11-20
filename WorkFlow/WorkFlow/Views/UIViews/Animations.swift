import SwiftUI


//struct ContentView: View {
//    var body: some View {
//  
//        Home()
//    }
//}


//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}


//struct Home: View {
//    
//    // Toggle For MultiColors...
//    @State var multiColor = false
//    
//    var body: some View{
//        
//        VStack(spacing: 25){
//            
//            TextShimmer(text: "Welcome", multiColors: $multiColor)
//            
//            TextShimmer(text: "Back", multiColors: $multiColor)
//            
//            TextShimmer(text: "Kavsoft", multiColors: $multiColor)
//            
//            Toggle(isOn: $multiColor, label: {
//                Text("Enable Multi Colors")
//                    .font(.title)
//                    .fontWeight(.bold)
//            })
//            .padding()
//        }
//        .preferredColorScheme(.dark)
//    }
//}


// TextShimmer....


struct TextShimmer: View {
    var text: String
    var fontSize: CGFloat // New property to specify font size
    @State var animation = false
    @Binding var multiColors: Bool

    var body: some View {
        ZStack {
            // Base text with a transparent white color to provide a shimmer effect background
            Text(text)
                .font(.system(size: fontSize, weight: .bold)) // Use the custom font size
                .foregroundColor(Color.white.opacity(0.25))

            // MultiColor Text - Each character is displayed separately with an optional random color
            HStack(spacing: 0) {
                ForEach(0..<text.count, id: \.self) { index in
                    Text(String(text[text.index(text.startIndex, offsetBy: index)]))
                        .font(.system(size: fontSize, weight: .bold)) // Use the custom font size
                        .foregroundColor(multiColors ? randomColor() : Color.white)
                }
            }
            // Masking For Shimmer Effect - The text is masked with a moving gradient for the shimmer
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: .init(colors: [
                                Color.white.opacity(0.5),
                                Color.white,
                                Color.white.opacity(0.5)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.init(degrees: 70)) // Rotate the gradient for a diagonal effect
                    .padding(20) // Add padding for a smoother animation
                    .offset(x: -250) // Start position for the gradient animation
                    .offset(x: animation ? 500 : 0) // End position for the gradient animation
            )
            .onAppear {
                // Infinite animation to toggle the shimmer effect
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    animation.toggle()
                }
            }
        }
    }

    // Random Color Function - Generates random colors for each character in the text
    func randomColor() -> Color {
        let color = UIColor(
            red: 1,
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1
        )
        return Color(color)
    }
}
