import SwiftUI
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "ItsFine.ContentView", category: "ContentView")
    
    @StateObject var viewModel = HeadlinesViewModel()
    @State private var animateDistortion: Bool = false
    @State private var randomOffsetX: CGFloat = 0
    @State private var randomOffsetY: CGFloat = 0
    @State private var randomBlur: CGFloat = 0
    @State private var randomRotation: Double = 0
    @State private var randomOpacity: Double = 1.0
    
    // Animation duration constant
    private let animationDuration: Double = 1.0
    // Number of glitch steps within the animation duration
    private let glitchSteps: Int = 10
    
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
                                .rotationEffect(.degrees(animateDistortion ? randomRotation : 0))
                                .opacity(animateDistortion ? randomOpacity : 1.0)
                                .animation(.easeInOut(duration: animationDuration / Double(glitchSteps)), value: animateDistortion)
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
        animateDistortion = true
        
        // Start glitch steps
        for step in 1...glitchSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration / Double(glitchSteps)) * Double(step)) {
                if step < self.glitchSteps {
                    // Generate random values for each glitch step
                    self.randomOffsetX = CGFloat.random(in: -30...30)
                    self.randomOffsetY = CGFloat.random(in: -15...15)
                    self.randomBlur = CGFloat.random(in: 10...20)
                    self.randomRotation = Double.random(in: -30...30)
                    self.randomOpacity = Double.random(in: 0.3...0.7)
                } else {
                    // Final step: return to normal state
                    self.randomOffsetX = 0
                    self.randomOffsetY = 0
                    self.randomBlur = 0
                    self.randomRotation = 0
                    self.randomOpacity = 1.0
                    self.animateDistortion = false
                }
            }
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
