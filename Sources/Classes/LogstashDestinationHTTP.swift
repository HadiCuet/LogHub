//  LogstashDestinationHTTP.swift

import Foundation

class LogstashDestinationHTTP: NSObject, LogstashDestinationSending {

    /// Default log type for Logz.io when not specified (matches Logz.io HTTP default parsing)
    private static let defaultLogzLogType = "http-bulk"

    /// Settings
    private let allowUntrustedServer: Bool
    private let host: String
    private let port: UInt16
    private let timeout: TimeInterval
    private let logActivity: Bool
    private let logzioToken: String?
    private let logType: String?

    private var session: URLSession
    var scheduler: LogstashDestinationSendingScheduling

    required init(host: String,
                  port: UInt16,
                  timeout: TimeInterval,
                  logActivity: Bool,
                  allowUntrustedServer: Bool = false,
                  logzioToken: String? = nil,
                  logType: String? = nil) {

        self.allowUntrustedServer = allowUntrustedServer
        self.host = host
        self.port = port
        self.timeout = timeout
        self.logActivity = logActivity
        self.logzioToken = logzioToken
        self.logType = logType ?? Self.defaultLogzLogType
        self.session = URLSession(configuration: .ephemeral)
        self.scheduler = LogstashDestinationSendingScheduler()
        super.init()
    }

    /// Cancel all active tasks and invalidate the session
    func cancel() {
        self.session.invalidateAndCancel()
        self.session = URLSession(configuration: .ephemeral)
    }

    /// Build the request URL: Logz.io format when token is set, generic path otherwise
    private func requestURL() -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = Int(port)

        if let token = logzioToken, !token.isEmpty {
            components.path = "/"
            components.queryItems = [
                URLQueryItem(name: "token", value: token),
                URLQueryItem(name: "type", value: logType ?? Self.defaultLogzLogType)
            ]
        } else {
            components.path = "/applications/logging"
        }

        return components.url
    }

    /// Create (and resume) stream tasks to send the logs provided to the server
    /// When using Logz.io (logzioToken set), sends all logs in a single batched POST with NDJSON body
    func sendLogs(_ logs: [Int: [String: Any]],
                  transform: @escaping LogstashDestinationSendingTransform,
                  queue: DispatchQueue,
                  complete: @escaping LogstashDestinationSendingCompletion) {
        Task {
            guard let url = requestURL() else {
                queue.async { complete([:]) }
                return
            }

            let isLogzIO = logzioToken != nil

            if isLogzIO && logs.count > 1 {
                // Batch: single POST with newline-separated JSON (NDJSON) for Logz.io
                let sortedLogs = logs.sorted(by: { $0.key < $1.key })
                var body = Data()
                for (_, content) in sortedLogs {
                    body.append(transform(content))
                }
                var sendStatus = [Int: Error]()
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = body
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("logzio-json-logs", forHTTPHeaderField: "User-Agent")
                    request.timeoutInterval = timeout
                    let (_, response) = try await session.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        let error = NSError(domain: "LogstashDestinationHTTP", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                        for (tag, _) in sortedLogs {
                            sendStatus[tag] = error
                        }
                    }
                } catch {
                    for (tag, _) in sortedLogs {
                        sendStatus[tag] = error
                    }
                }
                queue.async { complete(sendStatus) }
            } else {
                // One request per log (generic or single log)
                let sendStatus = await scheduler.scheduleSend(logs) { log in
                    let logData = transform(log)
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = logData
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = self.timeout
                    if isLogzIO {
                        request.setValue("logzio-json-logs", forHTTPHeaderField: "User-Agent")
                    }
                    _ = try await self.session.data(for: request)
                }
                queue.async { complete(sendStatus) }
            }
        }
    }
}
