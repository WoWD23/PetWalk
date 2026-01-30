//
//  LLMService.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import Foundation

enum LLMError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(String)
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let stream: Bool
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

actor LLMService {
    static let shared = LLMService()
    
    // MVP: Hardcoded key as per user request
    private let apiKey = "sk-0d363b2afc2d40378a469d8ba75af73c"
    private let baseURL = "https://api.deepseek.com/chat/completions"
    
    private init() {}
    
    func generateDiary(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: userPrompt)
        ]
        
        let payload = ChatRequest(
            model: "deepseek-chat", // or deepseek-reasoning depending on preference, chat is usually faster for this
            messages: messages,
            temperature: 1.3, // Slightly higher for creativity
            stream: false
        )
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("LLM API Error: \(errorString)")
                    throw LLMError.apiError("Status: \(httpResponse.statusCode)")
                }
                throw LLMError.apiError("Status: \(httpResponse.statusCode)")
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            
            guard let content = chatResponse.choices.first?.message.content else {
                throw LLMError.invalidResponse
            }
            
            return content
            
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.networkError(error)
        }
    }
}
