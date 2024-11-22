import Foundation

// MARK: - JobCategory Enum
enum JobCategory: String, CaseIterable, Codable {
    case landscaping = "Landscaping"
    case cleaning = "Cleaning"
    case construction = "Construction"
}
// MARK: - Job Struct
struct Job: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var number: String
    var description: String
    var city: String
    var category: JobCategory
    var datePosted: Date
    var imageURL: String?
    let latitude: Double?
    let longitude: Double?
}

// MARK: - NotificationModel Struct
struct NotificationModel: Identifiable, Hashable {
    var id: UUID
    var jobId: UUID
    var message: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(jobId)
        hasher.combine(message)
    }
    
    static func == (lhs: NotificationModel, rhs: NotificationModel) -> Bool {
        return lhs.id == rhs.id && lhs.jobId == rhs.jobId && lhs.message == rhs.message
    }
}
