import Fluent
import Vapor

struct HTMLConverterController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let converter = routes.grouped("convert")
        converter.post("html-to-markdown", use: convertHTML)
    }
    
    @Sendable
    func convertHTML(req: Request) async throws -> HTMLConverterResponseDTO {
        // 解码用户请求
        let converterRequest = try req.content.decode(HTMLConverterRequestDTO.self)
        
        // 验证用户输入
        guard !converterRequest.html.isEmpty else {
            throw Abort(.badRequest, reason: "HTML content cannot be empty")
        }
        
        // 使用HTML转换服务
        do {
            let (markdown, message) = try await req.htmlConverter.convertHTMLToMarkdown(
                html: converterRequest.html,
                options: converterRequest.options
            )
            
            // 返回转换结果
            return HTMLConverterResponseDTO(
                markdown: markdown,
                success: true,
                message: message
            )
        } catch {
            req.logger.error("HTML conversion failed: \(error)")
            return HTMLConverterResponseDTO(
                markdown: "",
                success: false,
                message: "Conversion failed: \(error.localizedDescription)"
            )
        }
    }
}