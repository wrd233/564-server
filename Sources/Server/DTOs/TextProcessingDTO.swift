import Vapor

// 基础文本处理请求DTO
protocol TextProcessingRequest: Content {
    var text: String { get }
}

// 基础文本处理响应DTO
protocol TextProcessingResponse: Content {}

// 摘要请求DTO
struct SummaryRequestDTO: TextProcessingRequest {
    var text: String
}

// 摘要响应DTO
struct SummaryResponseDTO: TextProcessingResponse {
    var summary: String
}

// 文章报告请求DTO
struct ReportRequestDTO: Content {
    /// 文章列表
    var articles: [Article]
    /// 报告标题（可选）
    var title: String?
    /// 报告风格（可选，如"学术"、"新闻"、"商业"等）
    var style: String?
    
    struct Article: Content {
        /// 文章标题（可选）
        var title: String?
        /// 文章内容
        var content: String
    }
}

// 文章报告响应DTO
struct ReportResponseDTO: Content {
    /// 生成的报告
    var report: String
    /// 报告生成时间
    var generatedAt: Date
}