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
    private var transformCallCount: Int = 0
    
    private let apiKey = APIKeys.openAIKey
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o" // Ensure this is the correct model name
    
    func transformHeadlines(_ headlines: [Headline], completion: @escaping (Result<[Headline], Error>) -> Void) {
        // Increment the transform call count
        transformCallCount += 1
        
        // Determine the optimization level based on the number of calls
        let promptModifier: String
        switch transformCallCount {
        case 1:
            promptModifier = ""
        case 2:
            promptModifier = "MORE satirical optimism..."
        case 3:
            promptModifier = "Even MORE satirical optimism..."
        case 4:
            promptModifier = "The very MOST satirical optimism..."
        default:
            promptModifier = "Totally unhinged absolutely satirical level of optimism"
        }
        
        // Construct the user message with the prompt modifier
        let headlinesText = headlines.map { $0.title }.joined(separator: "\n")
        let fullUserMessage = (promptModifier.isEmpty ? "" : "\(promptModifier)\n") + "Here are the headlines:\n\(headlinesText)"
        
        // Append user message to the conversation
        messages.append([
            "role": "user",
            "content": fullUserMessage
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
                
                // Parse the transformed titles
                let transformedTitles = self.parseHeadlines(from: assistantMessage)
                
                // Ensure the number of transformed titles matches the original headlines
                guard transformedTitles.count == headlines.count else {
                    let countError = NSError(domain: "OpenAIDataSource", code: -4, userInfo: [NSLocalizedDescriptionKey: "Transformed headlines count does not match original headlines count"])
                    completion(.failure(countError))
                    return
                }
                
                // Combine transformed titles with original URLs and dates
                let transformedHeadlines = zip(transformedTitles, headlines).map { transformedTitle, originalHeadline in
                    Headline(id: originalHeadline.id, title: transformedTitle, url: originalHeadline.url, date: originalHeadline.date)
                }
                
                completion(.success(transformedHeadlines))
                
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func parseHeadlines(from text: String) -> [String] {
        // Implement a simple parser to extract headlines from the assistant's response
        // This assumes that the assistant returns headlines separated by newlines
        // Adjust the parsing logic based on the actual response format
        let lines = text.split(separator: "\n").map { String($0) }
        return lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
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
}
