import SwiftUI
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "ItsFine.ContentView", category: "ContentView")
    
    @StateObject var viewModel = HeadlinesViewModel()
    @State private var animateDistortion: Bool = false
    @State private var randomOffsetX: CGFloat = 0
    @State private var randomOffsetY: CGFloat = 0
    @State private var randomBlur: CGFloat = 0
    
    // Animation duration constant
    private let animationDuration: Double = 1.0
    
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
                                .blur(radius: animateDistortion ? randomBlur : 0)
                                .offset(x: animateDistortion ? randomOffsetX : 0, y: animateDistortion ? randomOffsetY : 0)
                                .animation(.easeInOut(duration: animationDuration), value: animateDistortion)
                                .onTapGesture {
                                    // Optional: Handle headline tap if needed
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
            .background(
                ShakeDetectorView {
                    logger.info("SHAKE gesture detected! Transforming headlines and triggering animation...")
                    triggerDistortionAnimation()
                    viewModel.transformHeadlines()
                }
            )
        }
        .onAppear {
            logger.info("ContentView appeared.")
        }
    }
    
    private func triggerDistortionAnimation() {
        // Generate random values for offset and blur
        randomOffsetX = CGFloat.random(in: -10...10)
        randomOffsetY = CGFloat.random(in: -5...5)
        randomBlur = CGFloat.random(in: 2...5)
        
        // Start the animation
        animateDistortion = true
        
        // Revert the animation after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            animateDistortion = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Shake Gesture Detection

struct ShakeDetectorView: UIViewControllerRepresentable {
    var onShake: () -> Void
    
    class Coordinator: NSObject {
        var onShake: () -> Void
        
        init(onShake: @escaping () -> Void) {
            self.onShake = onShake
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onShake: onShake)
    }
    
    func makeUIViewController(context: Context) -> ShakeDetectorViewController {
        let viewController = ShakeDetectorViewController()
        viewController.onShake = context.coordinator.onShake
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ShakeDetectorViewController, context: Context) {
        // No update needed
    }
}

class ShakeDetectorViewController: UIViewController {
    var onShake: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Make the view transparent
        view.backgroundColor = .clear
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}
