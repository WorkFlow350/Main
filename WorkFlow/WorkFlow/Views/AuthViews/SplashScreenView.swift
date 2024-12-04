import SwiftUI

struct SplashScreenView: View {
    @State private var navigateToHome = false

    var body: some View {
        Group {
            if navigateToHome {
                DifferentiateView()
                    .environmentObject(AuthController())
                    .environmentObject(HomeownerJobController())
                    .environmentObject(JobController())
                    .environmentObject(FlyerController())
                    .environmentObject(BidController())
                    .environmentObject(ContractorController())
                    .environmentObject(ChatController())
            } else {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    VStack(spacing: 10) {
                        TextShimmer(text: "WELCOME", fontSize: 45, multiColors: .constant(true))
                        TextShimmer(text: "TO", fontSize: 45, multiColors: .constant(true))
                        TextShimmer(text: "WORKFLOW", fontSize: 45, multiColors: .constant(true))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        navigateToHome = true
                    }
                }
            }
        }
    }
}
