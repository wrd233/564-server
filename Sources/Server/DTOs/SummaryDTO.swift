import Vapor

// 用于接收用户请求的DTO
struct SummaryRequestDTO: Content {
    var text: String
}

// 用于返回摘要结果的DTO
struct SummaryResponseDTO: Content {
    var summary: String
}

// OpenAI API请求数据结构
struct OpenAIRequest: Content {
    var model: String
    var messages: [Message]
    var temperature: Double?
    var max_tokens: Int?
    
    struct Message: Content {
        var role: String
        var content: String
    }
}

// OpenAI API响应数据结构
struct OpenAIResponse: Content {
    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [Choice]
    
    struct Choice: Content {
        var index: Int
        var message: Message
        var finish_reason: String
    }
    
    struct Message: Content {
        var role: String
        var content: String
    }
}