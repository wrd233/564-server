import Fluent
import Vapor
import Foundation

struct SpeechController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let speech = routes.grouped("speech")
        speech.post(use: generateSpeech)
    }
    
    @Sendable
    func generateSpeech(req: Request) async throws -> Response {
        // 解码用户请求
        let speechRequest = try req.content.decode(SpeechRequestDTO.self)
        
        // 验证用户输入
        guard !speechRequest.text.isEmpty else {
            throw Abort(.badRequest, reason: "文本内容不能为空")
        }
        
        do {
            // 使用语音服务生成音频
            let audioBuffer = try await req.speech.textToSpeech(
                text: speechRequest.text,
                config: speechRequest.config
            )
            
            // 设置响应头
            let headers = HTTPHeaders([
                ("Content-Type", "audio/mpeg"),
                ("Content-Disposition", "attachment; filename=\"speech.mp3\""),
                ("Cache-Control", "no-cache")
            ])
            
            // 创建包含音频数据的响应
            let response = Response(status: .ok, headers: headers, body: .init(buffer: audioBuffer))
            return response
            
        } catch {
            req.logger.error("语音生成失败: \(error)")
            
            // 创建错误响应
            let errorResponse = SpeechProcessStatusDTO(
                status: "error",
                message: "语音生成失败",
                error: error.localizedDescription
            )
            
            let response = Response(status: .internalServerError)
            try response.content.encode(errorResponse, as: .json)
            return response
        }
    }
}