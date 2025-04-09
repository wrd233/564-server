import Fluent
import Vapor

struct SummaryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let summaries = routes.grouped("summary")
        summaries.post(use: createSummary)
    }
    
    @Sendable
    func createSummary(req: Request) async throws -> SummaryResponseDTO {
        // 解码用户请求
        let summaryRequest = try req.content.decode(SummaryRequestDTO.self)
        
        // 验证用户输入
        guard !summaryRequest.text.isEmpty else {
            throw Abort(.badRequest, reason: "Text cannot be empty")
        }
        
        // 获取API密钥
        guard let apiKey = Environment.get("OPENAI_API_KEY") else {
            req.logger.error("Missing OpenAI API key")
            throw Abort(.internalServerError, reason: "API configuration error")
        }
        
        // 创建OpenAI API请求
        let openAIRequest = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                .init(role: "system", content: "You are a helpful assistant that generates concise summaries."),
                .init(role: "user", content: "Please summarize the following text in a concise manner: \(summaryRequest.text)")
            ],
            temperature: 0.7,
            max_tokens: 300
        )
        
        // 发送请求到OpenAI API
        let openAIResponse = try await req.client.post("https://api.openai.com/v1/chat/completions") { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
            req.headers.contentType = .json
            try req.content.encode(openAIRequest)
        }
        
        // 处理OpenAI API响应
        do {
            let response = try openAIResponse.content.decode(OpenAIResponse.self)
            
            guard let content = response.choices.first?.message.content else {
                throw Abort(.internalServerError, reason: "Failed to get summary from OpenAI")
            }
            
            // 返回摘要响应
            return SummaryResponseDTO(summary: content)
        } catch {
            req.logger.error("Failed to decode OpenAI response: \(error)")
            throw Abort(.internalServerError, reason: "Failed to process the summary: \(error)")
        }
    }
}