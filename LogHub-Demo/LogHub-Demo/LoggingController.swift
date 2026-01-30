//
//  LoggingController.swift
//  LogHub-Demo
//

import Combine
import LogHub

@MainActor
class LoggingController: ObservableObject {

    static let shared = LoggingController()

    var logger: Logger?

    private init() {}

    func send(_ log: Log) {
        logger?.send(log)
    }

    func forceSend() {
        logger?.forceSend()
    }

    func cancelSending() {
        logger?.cancelSending()
    }

    func sanitize(_ message: String, _ type: LogType) -> String {
        guard let logger = logger else { return message }
        return logger.sanitize(message, type)
    }
}
