import Foundation

class OpenAIDataSource {
    static let shared = OpenAIDataSource()
    
    private init() {
        // Initialize with the system message
        messages.append([
            "role": "system",
            "content": "You are a headline conversion agent. You convert headlines to be more like what the user wants to read. The output is meant to be satire.\n\nMake the headlines a bit easier to read, less alarming, less dire. Put an optimistic spin on the headlines."
        ])
    }
    
    private var messages: [[String: String]] = []
    
    private let apiKey = APIKeys.openAIKey
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o" // Ensure this is the correct model name
    
    func transformHeadlines(_ headlines: [Headline], completion: @escaping (Result<[Headline], Error>) -> Void) {
        // Construct the headlines string
        let headlinesText = headlines.map { $0.title }.joined(separator: "\n")
        let userMessage = "Here are the headlines:\n\(headlinesText)"
        
        // Append user message to the conversation
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        // Prepare the request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        // Perform the network request
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let self = self else {
                let selfError = NSError(domain: "OpenAIDataSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])
                completion(.failure(selfError))
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "OpenAIDataSource", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received from OpenAI"])
                completion(.failure(noDataError))
                return
            }
            
            // Parse the response
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiResponse = try decoder.decode(OpenAIResponse.self, from: data)
                
                guard let assistantMessage = apiResponse.choices.first?.message.content else {
                    let parseError = NSError(domain: "OpenAIDataSource", code: -3, userInfo: [NSLocalizedDescriptionKey: "No assistant message found in response"])
                    completion(.failure(parseError))
                    return
                }
                
                // Append assistant message to the conversation
                self.messages.append([
                    "role": "assistant",
                    "content": assistantMessage
                ])
                
                // Convert assistant message to [Headline]
                let transformedHeadlines = self.parseHeadlines(from: assistantMessage)
                completion(.success(transformedHeadlines))
                
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func parseHeadlines(from text: String) -> [Headline] {
        // Implement a simple parser to extract headlines from the assistant's response
        // This assumes that the assistant returns headlines separated by newlines
        // Adjust the parsing logic based on the actual response format
        let lines = text.split(separator: "\n").map { String($0) }
        var transformedHeadlines: [Headline] = []
        
        for line in lines {
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let headline = Headline(id: UUID(), title: line, url: "", date: Date())
                transformedHeadlines.append(headline)
            }
        }
        
        return transformedHeadlines
    }
}

// Models for parsing OpenAI API responses

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
}

struct Choice: Codable {
    let index: Int
    let message: Message
    let finishReason: String?
}

struct Message: Codable {
    let role: String
    let content: String
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}
