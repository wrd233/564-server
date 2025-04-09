import Fluent
import Vapor
import Foundation

struct ReportController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let reports = routes.grouped("report")
        reports.post(use: generateReport)
    }
    
    @Sendable
    func generateReport(req: Request) async throws -> ReportResponseDTO {
        // 解码用户请求
        let reportRequest = try req.content.decode(ReportRequestDTO.self)
        
        // 验证用户输入
        guard !reportRequest.articles.isEmpty else {
            throw Abort(.badRequest, reason: "Articles list cannot be empty")
        }
        
        // 检查每篇文章是否有内容
        for (index, article) in reportRequest.articles.enumerated() {
            guard !article.content.isEmpty else {
                throw Abort(.badRequest, reason: "Article at index \(index) has empty content")
            }
        }
        
        // 获取API密钥
        guard let apiKey = Environment.get("OPENAI_API_KEY") else {
            req.logger.error("Missing OpenAI API key")
            throw Abort(.internalServerError, reason: "API configuration error")
        }
        
        // 构建提示词
        var articlesText = ""
        for (index, article) in reportRequest.articles.enumerated() {
            let articleTitle = article.title ?? "Article \(index + 1)"
            articlesText += "Article: \(articleTitle)\n\n\(article.content)\n\n---\n\n"
        }
        
        // 构建系统提示词
        var systemPrompt = "You are an expert content analyst and report generator. "
        
        if let style = reportRequest.style {
            systemPrompt += "Create a comprehensive report in \(style) style based on the provided articles. "
        } else {
            systemPrompt += "Create a comprehensive report based on the provided articles. "
        }
        
        systemPrompt += "The report should synthesize the information, highlight key points, identify patterns, and provide valuable insights. "
        systemPrompt += "Structure the report with clear sections including an executive summary, main findings, analysis, and conclusion."
        
        // 构建用户提示词
        var userPrompt = "Please generate a detailed report based on the following articles:\n\n\(articlesText)"
        
        if let title = reportRequest.title {
            userPrompt += "The report should be titled: \(title)\n"
        }
        
        // 使用OpenAI服务生成报告
        // 对于报告生成，我们使用更大的token限制
        let report = try await req.openAI.processText(
            apiKey: apiKey,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            model: "gpt-3.5-turbo-16k", // 使用更大上下文的模型
            maxTokens: 4000 // 允许生成较长的报告
        )
        
        // 返回报告响应
        return ReportResponseDTO(
            report: report,
            generatedAt: Date()
        )
    }
}