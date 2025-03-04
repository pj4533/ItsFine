import Foundation

struct Headline: Identifiable, Codable {
    let id: UUID
    var title: String
    var url: String
    var date: Date
}
