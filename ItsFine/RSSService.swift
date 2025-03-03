import Foundation
import os.log

class RSSService: NSObject {
    private let logger = Logger(subsystem: "ItsFine.RSSService", category: "RSSService")
    private let rssURL = URL(string: "https://rss.politico.com/politics-news.xml")!
    
    private var headlines: [Headline] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDate: Date = Date()
    private var count: Int = 0
    
    func fetchHeadlines(completion: @escaping (Result<[Headline], Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: rssURL) { [weak self] data, response, error in
            if let error = error {
                self?.logger.error("URLSession dataTask error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "RSSService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self?.logger.error("No data received from URLSession dataTask")
                completion(.failure(noDataError))
                return
            }
            
            // Convert data to string to extract <rss>...</rss>
            guard let htmlString = String(data: data, encoding: .utf8) else {
                let encodingError = NSError(domain: "RSSService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Data encoding failed"])
                self?.logger.error("Data encoding failed")
                completion(.failure(encodingError))
                return
            }
            
            // Find the <rss> start and end
            guard let rssStartRange = htmlString.range(of: "<rss", options: .caseInsensitive),
                  let rssEndRange = htmlString.range(of: "</rss>", options: .caseInsensitive) else {
                let invalidFormatError = NSError(domain: "RSSService", code: -3, userInfo: [NSLocalizedDescriptionKey: "RSS feed is not properly formatted"])
                self?.logger.error("RSS feed is not properly formatted. Cannot find <rss> tags.")
                completion(.failure(invalidFormatError))
                return
            }
            
            // Extract the <rss>...</rss> portion
            let rssContent = String(htmlString[rssStartRange.lowerBound..<rssEndRange.upperBound])
            
            // Convert back to Data for XMLParser
            guard let rssData = rssContent.data(using: .utf8) else {
                let dataConversionError = NSError(domain: "RSSService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to convert RSS content to Data"])
                self?.logger.error("Failed to convert RSS content to Data")
                completion(.failure(dataConversionError))
                return
            }
            
            let parser = XMLParser(data: rssData)
            parser.delegate = self
            if !parser.parse() {
                if let parserError = parser.parserError {
                    self?.logger.error("XMLParser failed: \(parserError.localizedDescription)")
                    completion(.failure(parserError))
                } else {
                    let unknownError = NSError(domain: "RSSService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unknown parsing error"])
                    self?.logger.error("XMLParser failed with unknown error")
                    completion(.failure(unknownError))
                }
                return
            }
            
            completion(.success(self?.headlines ?? []))
        }
        task.resume()
    }
}

extension RSSService: XMLParserDelegate {
    func parserDidStartDocument(_ parser: XMLParser) {
        headlines = []
        count = 0
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        // Parsing finished
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        logger.error("XMLParser encountered an error: \(parseError.localizedDescription)")
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        logger.error("XMLParser validation error: \(validationError.localizedDescription)")
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentDate = Date()
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedString.isEmpty { return }
        
        switch currentElement {
        case "title":
            currentTitle += trimmedString
        case "link":
            currentLink += trimmedString
        case "pubDate":
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
            if let date = formatter.date(from: trimmedString) {
                currentDate = date
            } else {
                logger.error("Date parsing failed for string: \(trimmedString)")
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let headline = Headline(title: currentTitle, url: currentLink, date: currentDate)
            headlines.append(headline)
            count += 1
            if count >= 10 {
                parser.abortParsing()
            }
        }
    }
}
