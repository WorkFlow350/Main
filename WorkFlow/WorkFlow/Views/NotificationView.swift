import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var jobController: JobController

    var body: some View {
        NavigationView {
            List(jobController.notifications, id: \.self) { notification in
                Text(notification)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            .navigationTitle("Notifications")
            .onAppear {
                // Listen for new job notifications
                NotificationCenter.default.addObserver(forName: Notification.Name("NewJobPosted"), object: nil, queue: .main) { _ in
                    // When a new notification is posted, the jobController's notifications array will automatically update due to @Published property
                }
            }
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView().environmentObject(JobController())
    }
}
