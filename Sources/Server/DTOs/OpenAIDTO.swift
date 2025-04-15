import Vapor

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

// Updated OpenAI API响应数据结构
struct OpenAIResponse: Content {
    // Made these properties optional to be more resilient to API changes
    var id: String?
    var object: String?
    var created: Int?
    var model: String?
    var choices: [Choice]
    var usage: Usage?
    
    struct Choice: Content {
        var index: Int?
        var message: Message
        var finish_reason: String?
    }
    
    struct Message: Content {
        var role: String
        var content: String
    }
    
    struct Usage: Content {
        var prompt_tokens: Int?
        var completion_tokens: Int?
        var total_tokens: Int?
    }
}