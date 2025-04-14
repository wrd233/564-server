import Vapor
import Foundation
import NIOCore

/// 语音转换服务
struct SpeechService {
    /// 客户端实例
    let client: any Client
    
    /// 日志记录器
    let logger: Logger
    
    /// 默认的音频块大小
    private let defaultChunkSize = 1000
    
    /// 默认的语音类型
    private let defaultVoice = "nova"
    
    /// 默认的语音模型
    private let defaultModel = "tts-1"
    
    /// 创建语音服务实例
    /// - Parameters:
    ///   - client: HTTP客户端
    ///   - logger: 日志记录器
    init(client: any Client, logger: Logger) {
        self.client = client
        self.logger = logger
    }
    
    /// 将文本转换为语音
    /// - Parameters:
    ///   - text: 输入文本
    ///   - config: 语音配置
    /// - Returns: 音频数据
    func textToSpeech(text: String, config: SpeechConfigDTO?) async throws -> ByteBuffer {
        // 验证文本内容
        guard !text.isEmpty else {
            throw Abort(.badRequest, reason: "文本内容不能为空")
        }
        
        // 获取API密钥
        guard let apiKey = Environment.get("OPENAI_API_KEY") else {
            logger.error("缺少OpenAI API密钥")
            throw Abort(.internalServerError, reason: "API配置错误")
        }
        
        // 配置语音参数
        let voice = config?.voice ?? defaultVoice
        let chunkSize = config?.chunkSize ?? defaultChunkSize
        let instructions = config?.instructions ?? "以自然流畅的方式朗读"
        
        // 截断文本为多个片段
        let chunks = chunkText(text, chunkSize: chunkSize)
        logger.info("文本已被分割为\(chunks.count)个片段进行处理")
        
        if chunks.isEmpty {
            throw Abort(.badRequest, reason: "处理后的文本为空")
        }
        
        // 处理每个文本片段
        var audioBuffers: [ByteBuffer] = []
        
        for (index, chunk) in chunks.enumerated() {
            do {
                logger.info("处理文本片段 \(index + 1)/\(chunks.count)")
                let buffer = try await generateSpeechForChunk(
                    chunk: chunk,
                    apiKey: apiKey,
                    voice: voice,
                    instructions: instructions
                )
                audioBuffers.append(buffer)
            } catch {
                logger.error("处理文本片段\(index + 1)失败: \(error)")
                throw error
            }
        }
        
        // 如果只有一个音频片段，直接返回
        if audioBuffers.count == 1 {
            return audioBuffers[0]
        }
        
        // 合并多个音频片段
        return try await mergeAudioBuffers(audioBuffers)
    }
    
    /// 将文本分割为多个片段
    /// - Parameters:
    ///   - text: 输入文本
    ///   - chunkSize: 每个片段的最大字符数
    /// - Returns: 文本片段数组
    private func chunkText(_ text: String, chunkSize: Int) -> [String] {
        if text.count <= chunkSize {
            return [text]
        }
        
        var chunks: [String] = []
        var currentIndex = text.startIndex
        
        while currentIndex < text.endIndex {
            let endIndex = text.index(currentIndex, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            
            // 寻找最近的句子结束符（句号、问号、感叹号）或段落结束
            var breakIndex = endIndex
            if endIndex != text.endIndex {
                // 从结束位置向前查找最近的句子边界
                var searchIndex = endIndex
                while searchIndex > currentIndex {
                    searchIndex = text.index(before: searchIndex)
                    let char = text[searchIndex]
                    if char == "." || char == "?" || char == "!" || char == "\n" {
                        breakIndex = text.index(after: searchIndex)
                        break
                    }
                }
                
                // 如果没有找到句子边界，则查找空格
                if breakIndex == endIndex {
                    searchIndex = endIndex
                    while searchIndex > currentIndex {
                        searchIndex = text.index(before: searchIndex)
                        if text[searchIndex] == " " {
                            breakIndex = text.index(after: searchIndex)
                            break
                        }
                    }
                }
            }
            
            // 提取当前片段
            let chunk = String(text[currentIndex..<breakIndex])
            if !chunk.isEmpty {
                chunks.append(chunk)
            }
            
            // 更新索引
            currentIndex = breakIndex
        }
        
        return chunks
    }
    
    /// 为单个文本片段生成语音
    /// - Parameters:
    ///   - chunk: 文本片段
    ///   - apiKey: OpenAI API密钥
    ///   - voice: 语音类型
    ///   - instructions: 语音指示
    /// - Returns: 音频数据
    private func generateSpeechForChunk(
        chunk: String,
        apiKey: String,
        voice: String,
        instructions: String
    ) async throws -> ByteBuffer {
        // 创建OpenAI API请求
        let openAIRequest = OpenAISpeechRequestDTO(
            model: defaultModel,
            input: chunk,
            voice: voice,
            instructions: instructions
        )
        
        // 发送请求到OpenAI API
        let response = try await client.post("https://api.openai.com/v1/audio/speech") { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
            req.headers.contentType = .json
            try req.content.encode(openAIRequest)
        }
        
        // 处理响应
        if response.status != .ok {
            let errorMessage = response.body.map { buffer in
                buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) ?? "未知错误"
            } ?? "未知错误"
            
            logger.error("OpenAI API错误: \(errorMessage)")
            throw Abort(.internalServerError, reason: "语音生成失败: \(errorMessage)")
        }
        
        guard let buffer = response.body else {
            throw Abort(.internalServerError, reason: "从API获取的响应为空")
        }
        
        return buffer
    }
    
    /// 合并多个音频缓冲区
    /// - Parameter buffers: 音频缓冲区数组
    /// - Returns: 合并后的音频数据
    private func mergeAudioBuffers(_ buffers: [ByteBuffer]) async throws -> ByteBuffer {
        // 如果只有一个缓冲区，直接返回
        if buffers.count == 1 {
            return buffers[0]
        }
        
        // 注意：这里使用简单的字节拼接方法
        // 对于MP3文件，直接拼接可能导致音频播放问题
        // 更完善的实现应该使用专业的音频处理库
        
        // 创建一个新的ByteBuffer来存储合并的数据
        var result = ByteBuffer()
        
        // 遍历所有缓冲区，将数据追加到结果缓冲区
        for (index, buffer) in buffers.enumerated() {
            if index == 0 {
                // 对于第一个MP3文件，保留完整内容
                result.writeBytes(buffer.readableBytesView)
            } else {
                // 对于后续MP3文件，我们需要更复杂的处理
                // 这是简化的实现，实际上应该使用专业的音频处理库
                // 这种方法可能在某些MP3文件上不工作
                result.writeBytes(buffer.readableBytesView)
            }
        }
        
        return result
    }
}

// 扩展Request，便于获取服务实例
extension Request {
    var speech: SpeechService {
        .init(client: self.client, logger: self.logger)
    }
}