import Foundation

// An enumeration defining the different categories a job can belong to.
// Each case represents a type of job category, and it's Codable to support encoding/decoding.
enum JobCategory: String, CaseIterable, Codable {
    case landscaping = "Landscaping"    // Jobs related to landscaping (e.g., gardening, tree trimming).
    case cleaning = "Cleaning"          // Jobs related to cleaning (e.g., house cleaning, car washing).
    case construction = "Construction"  // Jobs related to construction (e.g., plumbing, repairs).
}

// A structure representing a job, which conforms to Identifiable and Codable protocols.
struct Job: Identifiable, Codable {
    var id: UUID                        // Unique identifier for each job.
    var title: String                   // Title of the job (e.g., "Gardener").
    var description: String             // A brief description of the job (e.g., "Maintenance of rose garden").
    var city: String                    // The city where the job is located.
    var category: JobCategory           // The category of the job, defined by the JobCategory enum.
    var datePosted: Date                // The date when the job was posted.
    var imageURL: String?               // Optional URL for an image associated with the job.
}
