import Vapor
import Foundation

/// 语音请求DTO
struct SpeechRequestDTO: Content {
    /// 要转换为语音的文本
    var text: String
    
    /// 语音配置选项
    var config: SpeechConfigDTO?
}

/// 语音配置DTO
struct SpeechConfigDTO: Content {
    /// 语音类型选项: alloy, echo, fable, onyx, nova, shimmer, coral
    var voice: String?
    
    /// 语音指示，如"兴奋的"、"平静的"、"专业的"等
    var instructions: String?
    
    /// 每个音频片段的最大字符数
    var chunkSize: Int?
}

/// OpenAI语音API请求格式
struct OpenAISpeechRequestDTO: Content {
    /// 使用的模型
    var model: String
    
    /// 输入文本
    var input: String
    
    /// 语音类型
    var voice: String
    
    /// 语音指示
    var instructions: String?
}

/// 语音处理状态响应
struct SpeechProcessStatusDTO: Content {
    /// 处理状态
    var status: String
    
    /// 处理信息
    var message: String?
    
    /// 错误信息
    var error: String?
}