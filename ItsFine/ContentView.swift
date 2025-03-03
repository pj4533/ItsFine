import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = HeadlinesViewModel()
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView("Loading Headlines...")
                    .navigationTitle("Headlines")
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Button(action: {
                        viewModel.fetchHeadlines()
                    }) {
                        Text("Retry")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .navigationTitle("Headlines")
            } else {
                List(viewModel.headlines) { headline in
                    VStack(alignment: .leading) {
                        Text(headline.title)
                            .font(.headline)
                        Text(headline.url)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                            .onTapGesture {
                                if let url = URL(string: headline.url) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        Text(headline.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .refreshable {
                    viewModel.fetchHeadlines()
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
