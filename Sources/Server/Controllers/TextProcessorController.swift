// import Fluent
// import Vapor

// struct TextProcessorController: RouteCollection {
//     func boot(routes: any RoutesBuilder) throws {
//         let textProcessor = routes.grouped("process-text")
//         textProcessor.post(use: processText)
//     }
    
//     @Sendable
//     func processText(req: Request) async throws -> TextProcessorResponseDTO {
//         // 解码用户请求
//         let textRequest = try req.content.decode(TextProcessorRequestDTO.self)
        
//         // 验证用户输入
//         guard !textRequest.text.isEmpty else {
//             throw Abort(.badRequest, reason: "Text cannot be empty")
//         }
        
//         // 获取API密钥
//         guard let apiKey = Environment.get("OPENAI_API_KEY") else {
//             req.logger.error("Missing OpenAI API key")
//             throw Abort(.internalServerError, reason: "API configuration error")
//         }
        
//         // 根据文本长度确定使用哪个模型
//         // 使用2000字符作为长文本的阈值
//         let isLongText = textRequest.text.count > 2000
//         let modelToUse = isLongText ? "o3-mini-2025-01-31" : "gpt-4o-2024-08-06"
//         req.logger.info("选择模型: \(modelToUse) (文本长度: \(textRequest.text.count)字符)")
        
//         // 创建OpenAI API请求
//         let openAIRequest = OpenAIRequest(
//             model: modelToUse,
//             messages: [
//                 .init(role: "system", content: """
//                 Take the provided English text and convert it into an ADHD-friendly format. 
//                 For each word deemed relatively important (excluding common stop words such as articles, prepositions, and conjunctions), 
//                 apply bold formatting (using Markdown syntax) to the first 2–3 characters of that word. 
//                 The transformation should preserve the original text exactly in terms of content and structure, 
//                 only adding the bold formatting to the leading characters of key words.
//                 Always return the processed text in Markdown format, regardless of input format.
//                 """),
//                 .init(role: "user", content: textRequest.text)
//             ],
//             temperature: 0.5,
//             max_tokens: 4000
//         )
        
//         // 发送请求到OpenAI API
//         let openAIResponse = try await req.client.post("https://api.openai.com/v1/chat/completions") { req in
//             req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
//             req.headers.contentType = .json
//             try req.content.encode(openAIRequest)
//         }
        
//         // 处理OpenAI API响应
//         do {
//             let response = try openAIResponse.content.decode(OpenAIResponse.self)
            
//             guard let content = response.choices.first?.message.content else {
//                 throw Abort(.internalServerError, reason: "Failed to get processed text from OpenAI")
//             }
            
//             // 返回处理后的文本
//             return TextProcessorResponseDTO(processedText: content)
//         } catch {
//             req.logger.error("Failed to decode OpenAI response: \(error)")
//             throw Abort(.internalServerError, reason: "Failed to process the text: \(error)")
//         }
//     }
// }




import Fluent
import Vapor

struct TextProcessorController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let textProcessor = routes.grouped("process-text")
        textProcessor.post(use: processText)
    }
    
    @Sendable
    func processText(req: Request) async throws -> TextProcessorResponseDTO {
        // 解码用户请求
        let textRequest = try req.content.decode(TextProcessorRequestDTO.self)
        
        // 验证用户输入
        guard !textRequest.text.isEmpty else {
            throw Abort(.badRequest, reason: "Text cannot be empty")
        }
        
        // 获取API密钥
        guard let apiKey = Environment.get("OPENAI_API_KEY") else {
            req.logger.error("Missing OpenAI API key")
            throw Abort(.internalServerError, reason: "API configuration error")
        }
        
        // 使用OpenAI服务处理文本
        let processedText = try await req.openAI.processText(
            apiKey: apiKey,
            systemPrompt: """
                Take the provided English text and convert it into an ADHD-friendly format. 
                For each word deemed relatively important (excluding common stop words such as articles, prepositions, and conjunctions), 
                apply bold formatting (using Markdown syntax) to the first 2–3 characters of that word. 
                The transformation should preserve the original text exactly in terms of content and structure, 
                only adding the bold formatting to the leading characters of key words.
                Always return the processed text in Markdown format, regardless of input format.
                """,
            userPrompt: " \(textRequest.text)"
        )
        
        // 返回摘要响应
        return TextProcessorResponseDTO(processedText: processedText)
    }
}