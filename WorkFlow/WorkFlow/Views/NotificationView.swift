import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var jobController: JobController

    var body: some View {
        NavigationStack {
            List {
                // finds corresponding job and passes it into JobView()
                // lists notifications as clickable navigations
                ForEach(jobController.notifications, id: \.self) { notification in
                    if let job = jobController.jobs.first(where: {$0.id == notification.jobId}) {
                        NavigationLink(value: job) {
                            Text(notification.message)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationDestination(for: Job.self) { selectedJob in
                JobView(job: selectedJob)}
            .onAppear {
                // Listen for new job notifications
                NotificationCenter.default.addObserver(forName: Notification.Name("NewJobPosted"), object: nil, queue: .main) { _ in
                    // When a new notification is posted, the jobController's notifications array will automatically update due to @Published property
                }
            }
        }
        .onDisappear {
            // removes observer so no unexpected notifications reappear
            NotificationCenter.default.removeObserver(self, name: Notification.Name("NewJobPosted"), object: nil)
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView().environmentObject(JobController())
    }
}
