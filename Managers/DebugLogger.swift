// DebugLogger.swift
import Foundation

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()

    @Published var logs: [String] = []
    private let maxLogs = 500 // 最多保留500条日志

    private var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("running_debug.log")
    }

    private init() {
        loadLogs()
    }

    func log(_ message: String, category: String = "INFO") {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [\(category)] \(message)"

        // 添加到内存
        DispatchQueue.main.async {
            self.logs.append(logMessage)
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst()
            }
        }

        // 同时打印到控制台
        print(logMessage)

        // 写入文件
        DispatchQueue.global(qos: .background).async {
            self.appendToFile(logMessage)
        }
    }

    private func appendToFile(_ message: String) {
        let line = message + "\n"

        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    private func loadLogs() {
        if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
            logs = Array(lines.suffix(maxLogs))
        }
    }

    func clearLogs() {
        logs.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
        log("日志已清空", category: "SYSTEM")
    }

    func exportLogs() -> String {
        return logs.joined(separator: "\n")
    }
}
