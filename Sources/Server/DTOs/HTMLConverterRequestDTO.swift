import Vapor

/// HTML转换请求DTO
struct HTMLConverterRequestDTO: Content {
    /// 需要转换的HTML内容
    var html: String
    
    /// 转换选项
    var options: ConversionOptions?
    
    /// 转换选项
    struct ConversionOptions: Content {
        /// 是否保留图片链接
        var preserveImages: Bool?
        
        /// 是否添加目录
        var addTableOfContents: Bool?
        
        /// 转换为GitHub风格的Markdown
        var githubFlavored: Bool?
    }
}

/// HTML转换响应DTO
struct HTMLConverterResponseDTO: Content {
    /// 转换后的Markdown内容
    var markdown: String
    
    /// 转换是否成功
    var success: Bool
    
    /// 转换消息（可能包含警告）
    var message: String?
}