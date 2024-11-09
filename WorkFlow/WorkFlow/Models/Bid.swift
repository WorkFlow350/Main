import Foundation

// MARK: - Bid Struct
struct Bid: Identifiable, Equatable {
    let id: UUID
    let jobId: String
    let contractorId: String        // This is current sessions Id
    let homeownerId: String         // Owner of the job listing
    let price: Double
    let description: String
    let status: bidStatus
    let bidDate: Date
    
    enum bidStatus: String {
        case pending
        case accepted
        case declined
    }
}
