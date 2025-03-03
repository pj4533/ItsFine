import Foundation

struct Headline: Identifiable {
    let id = UUID()
    var title: String
    var url: String
    var date: Date
}
