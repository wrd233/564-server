import Vapor
import Foundation
import NIOCore

/// 服务类，用于HTML到Markdown的转换
struct HTMLConverterService {
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    /// 使用pandoc将HTML转换为Markdown
    /// - Parameters:
    ///   - html: HTML内容
    ///   - options: 转换选项
    /// - Returns: 转换后的Markdown文本和状态信息
    func convertHTMLToMarkdown(
        html: String,
        options: HTMLConverterRequestDTO.ConversionOptions? = nil
    ) async throws -> (markdown: String, message: String?) {
        // 创建临时文件来存储HTML内容
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("input-\(UUID().uuidString).html")
        let outputFile = tempDir.appendingPathComponent("output-\(UUID().uuidString).md")
        
        do {
            // 写入HTML到临时文件
            try html.write(to: inputFile, atomically: true, encoding: .utf8)
            
            // 构建pandoc命令参数
            var arguments = [
                inputFile.path,
                "-o", outputFile.path,
                "--wrap=none"  // 避免自动换行
            ]
            
            // 添加选项
            if let options = options {
                if options.githubFlavored == true {
                    arguments.append("--to=gfm")  // GitHub风格Markdown
                } else {
                    arguments.append("--to=markdown")
                }
                
                if options.addTableOfContents == true {
                    arguments.append("--toc")
                }
                
                if options.preserveImages == false {
                    arguments.append("--extract-media=no")
                }
            } else {
                arguments.append("--to=markdown")
            }
            
            // 创建Process来执行pandoc命令
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pandoc")
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            // 执行转换
            logger.info("Executing pandoc with arguments: \(arguments.joined(separator: " "))")
            try process.run()
            process.waitUntilExit()
            
            // 检查执行状态
            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                logger.error("Pandoc conversion failed: \(errorMessage)")
                
                // 转换失败时返回原始HTML
                return (markdown: html, message: "Conversion failed, returning original HTML. Error: \(errorMessage)")
            }
            
            // 读取转换结果
            let markdown = try String(contentsOf: outputFile, encoding: .utf8)
            
            // 清理临时文件
            try FileManager.default.removeItem(at: inputFile)
            try FileManager.default.removeItem(at: outputFile)
            
            return (markdown: markdown, message: nil)
        } catch {
            // 确保清理临时文件
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: outputFile)
            
            logger.error("HTML conversion error: \(error)")
            
            // 任何错误情况下返回原始HTML
            return (markdown: html, message: "Conversion failed, returning original HTML. Error: \(error.localizedDescription)")
        }
    }
}

// 扩展Request，便于获取服务实例
extension Request {
    var htmlConverter: HTMLConverterService {
        .init(logger: self.logger)
    }
}