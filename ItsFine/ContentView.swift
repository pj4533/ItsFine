import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = HeadlinesViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView()
                    .navigationTitle("Headlines")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .navigationTitle("Headlines")
            } else {
                List(viewModel.headlines, id: \.title) { headline in
                    VStack(alignment: .leading) {
                        Text(headline.title)
                            .font(.headline)
                        Text(headline.url)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                        Text(headline.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Headlines")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
