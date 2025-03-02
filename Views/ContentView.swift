import SwiftUI

struct ContentView: View {
    let headlines: [Headline] = [
        Headline(title: "Headline 1", url: "https://example.com/1", date: Date()),
        Headline(title: "Headline 2", url: "https://example.com/2", date: Date()),
        Headline(title: "Headline 3", url: "https://example.com/3", date: Date()),
        Headline(title: "Headline 4", url: "https://example.com/4", date: Date()),
        Headline(title: "Headline 5", url: "https://example.com/5", date: Date())
    ]
    
    var body: some View {
        List(headlines, id: \.title) { headline in
            Text(headline.title)
        }
        .navigationTitle("Headlines")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
