import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        
        // Create a custom configuration with timeout settings
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0  // 30 seconds for request timeout
        configuration.timeoutIntervalForResource = 60.0 // 60 seconds for resource timeout
        configuration.waitsForConnectivity = true       // Wait for connectivity if offline
        
        self.session = URLSession(configuration: configuration)
    }
    
    func extractIdeas(from text: String) async throws -> [String] {
        let prompt = """
        Extract and list all the core ideas, frameworks, and insights from the non-fiction book titled "\(text)". 
        Return them as a JSON array of strings.

        \(text)
        """


        let systemPrompt = """
            Your task is to extract and list the most important, teachable ideas from a non-fiction book.

            Each concept = one distinct, self-contained idea. No overlaps. No vague summaries.

            Prefer explanatory power over catchy phrasing. Extract the mental models, distinctions, frameworks, and cause-effect patterns that drive the book.

            Give the concept a short, clear title (1 line max) and a brief explanation (1–2 lines).

            Focus only on the most important + teachable ideas. Do not include trivia or examples unless essential.

            Ignore chapter structure. Group similar ideas under unified concepts.

            Aim for 10–50 concepts per book, depending on richness.

            Don’t quote—explain.

            Additional rules for this API call:
            • Titles must be unique. Do not output synonyms or sub-variants as separate items.  
            • Prepend each concept with an ID in the form **i1, i2, …** so the client can parse it.  
            Example output element: `"i7 | Anchoring effect — Initial numbers bias estimates even when irrelevant."`
            • If more than 25 unique concepts remain, keep only the 25 most important, then maintain narrative order.

            Return a **JSON array of strings** (no objects, no extra text).
        """

        
        let requestBody = ChatRequest(
            model: "gpt-3.5-turbo",
            messages: [
                Message(role: "system", content: systemPrompt),
                Message(role: "user", content: prompt)
            ],
            max_tokens: 1000,
            temperature: 0.3
        )
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OpenAIServiceError.networkError(error)
        }
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIServiceError.invalidResponse
        }
        
        let chatResponse: ChatResponse
        do {
            chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw OpenAIServiceError.decodingError(error)
        }
        
        guard let content = chatResponse.choices.first?.message.content else {
            throw OpenAIServiceError.noResponse
        }
        
        #if DEBUG
        print("🧠 Raw OpenAI content:", content)
        #endif
        
        guard let contentData = content.data(using: .utf8) else {
            throw OpenAIServiceError.noResponse
        }
        
        do {
            return try JSONDecoder().decode([String].self, from: contentData)
        } catch {
            throw OpenAIServiceError.decodingError(error)
        }
    }
}

// MARK: - Models
struct ChatRequest: Codable {
    let model: String
    let messages: [Message]
    let max_tokens: Int
    let temperature: Double
}

struct Message: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

enum OpenAIServiceError: Error {
    case noResponse
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
}
