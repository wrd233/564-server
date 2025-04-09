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