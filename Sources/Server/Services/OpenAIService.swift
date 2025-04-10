import Vapor

/// 服务类，封装与OpenAI API的交互
struct OpenAIService {
    let client: any Client
    let logger: Logger
    
    init(client: any Client, logger: Logger) {
        self.client = client
        self.logger = logger
    }
    
    /// 向OpenAI API发送请求并处理响应
    /// - Parameters:
    ///   - apiKey: OpenAI API密钥
    ///   - systemPrompt: 系统提示词
    ///   - userPrompt: 用户提示词
    ///   - model: 使用的模型
    ///   - maxTokens: 最大令牌数
    /// - Returns: 处理后的文本响应
    func processText(
        apiKey: String,
        systemPrompt: String,
        userPrompt: String,
        model: String = "gpt-3.5-turbo",
        maxTokens: Int = 300
    ) async throws -> String {
        // 创建OpenAI API请求
        let openAIRequest = OpenAIRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0.7,
            max_tokens: maxTokens
        )
        
        // 发送请求到OpenAI API
        let openAIResponse = try await client.post("https://api.openai.com/v1/chat/completions") { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
            req.headers.contentType = .json
            try req.content.encode(openAIRequest)
        }
        
        // 处理OpenAI API响应
        do {
            let response = try openAIResponse.content.decode(OpenAIResponse.self)
            
            guard let content = response.choices.first?.message.content else {
                throw Abort(.internalServerError, reason: "Failed to get content from OpenAI")
            }
            
            return content
        } catch {
            logger.error("Failed to decode OpenAI response: \(error)")
            throw Abort(.internalServerError, reason: "Failed to process text: \(error)")
        }
    }
}

// 扩展Request，便于获取服务实例
extension Request {
    var openAI: OpenAIService {
        .init(client: self.client, logger: self.logger)
    }
}