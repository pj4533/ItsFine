import SwiftUI
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "ItsFine.ContentView", category: "ContentView")
    
    @StateObject var viewModel = HeadlinesViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    VStack {
                        ProgressView("Loading Headlines...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(2)
                        Text("Fetching the latest news...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .navigationTitle("Headlines")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.red)
                        Text("Failed to load headlines.")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .foregroundColor(.gray)
                        Button(action: {
                            viewModel.fetchHeadlines()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .navigationTitle("Headlines")
                } else {
                    List(viewModel.headlines) { headline in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(headline.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .onTapGesture {
                                    logger.debug("Tapped on headline: \(headline.title)")
                                }
                            Text(headline.url)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                                .onTapGesture {
                                    if let url = URL(string: headline.url) {
                                        logger.debug("Opening URL: \(headline.url)")
                                        UIApplication.shared.open(url)
                                    } else {
                                        logger.error("Invalid URL: \(headline.url)")
                                    }
                                }
                            Text(headline.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        logger.info("Pull-to-refresh activated.")
                        viewModel.fetchHeadlines()
                    }
                    .navigationTitle("Headlines")
                }
            }
        }
        .onAppear {
            logger.info("ContentView appeared.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
