//
//  ContentView.swift
//  LogHub-Demo
//

import SwiftUI
import LogHub

struct ContentView: View {
    @EnvironmentObject var loggingController: LoggingController
    @State private var logNumber = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("LogHub Demo")
                    .font(.title)
                    .padding(.bottom, 8)

                Button("Verbose") {
                    let log = Log(type: .verbose, message: "[\(logNumber)] not so important", customData: ["userInfo key": "userInfo value"])
                    loggingController.send(log)
                    logNumber += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Debug") {
                    let log = Log(type: .debug, message: "[\(logNumber)] not so debug", customData: ["userInfo key": "userInfo value"])
                    loggingController.send(log)
                    logNumber += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Info") {
                    let log = Log(type: .info, message: "[\(logNumber)] a nice information", customData: ["userInfo key": "userInfo value"])
                    loggingController.send(log)
                    logNumber += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Warning") {
                    let log = Log(type: .warning, message: "[\(logNumber)] oh no, that won't be good", customData: ["userInfo key": "userInfo value"])
                    loggingController.send(log)
                    logNumber += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Warning (Sanitized)") {
                    let messageToSanitize = "conversation ={\\n id = \\\"123455\\\";\\n};\\n from = {\\n id = 123456;\\n name = \\\"John Smith\\\";\\n; \\n token = \\\"123456\\\";\\n"
                    let sanitizedMessage = loggingController.sanitize(messageToSanitize, .warning)
                    let log = Log(type: .warning, message: sanitizedMessage, customData: ["userInfo key": "userInfo value"])
                    loggingController.send(log)
                    logNumber += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Error") {
                    let underlyingUnreadableUserInfoError: [String: Any] = [
                        NSLocalizedFailureReasonErrorKey: "inner error value".data(using: .utf8)!,
                        NSLocalizedDescriptionKey: "inner description",
                        NSLocalizedRecoverySuggestionErrorKey: "inner recovery suggestion".data(using: .utf8)!
                    ]

                    let unreadableUserInfos: [String: Any] = [
                        NSUnderlyingErrorKey: NSError(domain: "com.loghub.test.inner", code: 5678, userInfo: underlyingUnreadableUserInfoError),
                        NSLocalizedFailureReasonErrorKey: "error value".data(using: .utf8)!,
                        NSLocalizedDescriptionKey: "description",
                        NSLocalizedRecoverySuggestionErrorKey: "recovery suggestion".data(using: .utf8)!
                    ]

                    let unreadableError = NSError(domain: "com.loghub.test", code: 1234, userInfo: unreadableUserInfos)

                    let log = Log(type: .error, message: "[\(logNumber)] ouch, an error did occur!", error: unreadableError, customData: ["userInfo key": "userInfo value"])
                    loggingController.send(log)
                    logNumber += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Force Send") {
                    loggingController.forceSend()
                }
                .buttonStyle(.bordered)

                Button("Cancel") {
                    loggingController.cancelSending()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LoggingController.shared)
}
