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
        
        // 使用OpenAI服务处理文本
        let summary = try await req.openAI.processText(
            apiKey: apiKey,
            systemPrompt: "You are a helpful assistant that generates concise summaries.",
            userPrompt: "Please summarize the following text in a concise manner: \(summaryRequest.text)"
        )
        
        // 返回摘要响应
        return SummaryResponseDTO(summary: summary)
    }
}