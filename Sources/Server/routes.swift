import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: TodoController())
    try app.register(collection: SummaryController())
    try app.register(collection: ReportController())
    try app.register(collection: HTMLConverterController())
    try app.register(collection: TextProcessorController())
}