//
//  LocalTokenScanner.swift
//  Usage Notch
//

import Foundation

public struct LocalTokenStats {
    public var inputTokensToday: Int = 0
    public var outputTokensToday: Int = 0
    public var cachedTokensToday: Int = 0
    public var totalTokensToday: Int = 0
    
    public var inputTokensMonth: Int = 0
    public var outputTokensMonth: Int = 0
    public var cachedTokensMonth: Int = 0
    public var totalTokensMonth: Int = 0
    
    public var sessionsCountToday: Int = 0
    public var sessionsCountMonth: Int = 0
    
    public var estimatedCostTodayUSD: Double = 0.0
    public var estimatedCostMonthUSD: Double = 0.0
    
    public var formattedTodayString: String {
        let tokStr = formatTokenCount(totalTokensToday)
        let costStr = String(format: "$%.2f", estimatedCostTodayUSD)
        return "\(tokStr) · \(costStr)"
    }
    
    public var formattedMonthString: String {
        let tokStr = formatTokenCount(totalTokensMonth)
        let costStr = String(format: "$%.2f", estimatedCostMonthUSD)
        return "\(tokStr) · \(costStr)"
    }
    
    public func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000_000 {
            return String(format: "%.2fb", Double(count) / 1_000_000_000.0)
        } else if count >= 1_000_000 {
            return String(format: "%.2fm", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }
}

public final class LocalTokenScanner: @unchecked Sendable {
    public static let shared = LocalTokenScanner()
    
    private let fileManager = FileManager.default
    
    // MARK: - Scan Codex Sessions (~/.codex/sessions)
    public func scanCodexSessions() -> LocalTokenStats? {
        let home = fileManager.homeDirectoryForCurrentUser
        let codexDir = home.appendingPathComponent(".codex/sessions")
        
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: codexDir.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        
        let now = Date()
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) ?? now
        
        var stats = LocalTokenStats()
        
        guard let enumerator = fileManager.enumerator(
            at: codexDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        var foundAny = false
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }
            guard let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = values.contentModificationDate,
                  modDate >= thirtyDaysAgo else {
                continue
            }
            
            foundAny = true
            let isToday = modDate >= startOfToday
            if isToday {
                stats.sessionsCountToday += 1
            }
            stats.sessionsCountMonth += 1
            
            parseCodexJsonlFile(at: fileURL, isToday: isToday, stats: &stats)
        }
        
        guard foundAny else { return nil }
        
        // Compute total tokens: input + output
        stats.totalTokensToday = stats.inputTokensToday + stats.outputTokensToday
        stats.totalTokensMonth = stats.inputTokensMonth + stats.outputTokensMonth
        
        // Blended OpenAI model cost estimate: ~$2.50/M input, ~$10.00/M output, ~$1.25/M cached
        stats.estimatedCostTodayUSD = (Double(stats.inputTokensToday) * 0.0000025) +
                                      (Double(stats.outputTokensToday) * 0.0000100) +
                                      (Double(stats.cachedTokensToday) * 0.00000125)
        
        stats.estimatedCostMonthUSD = (Double(stats.inputTokensMonth) * 0.0000025) +
                                      (Double(stats.outputTokensMonth) * 0.0000100) +
                                      (Double(stats.cachedTokensMonth) * 0.00000125)
        
        return stats
    }
    
    private func parseCodexJsonlFile(at url: URL, isToday: Bool, stats: inout LocalTokenStats) {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return
        }
        
        for line in content.split(separator: "\n") {
            // Fast filter for token count events
            guard line.contains("token_count") || line.contains("input_tokens") || line.contains("output_tokens") else {
                continue
            }
            
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }
            
            var inp = 0
            var out = 0
            var cached = 0
            
            // Format 1: { "type": "token_count", "input_tokens": 1234, "output_tokens": 56, "cached_input_tokens": 500 }
            if let countObj = json["token_count"] as? [String: Any] {
                inp = countObj["input_tokens"] as? Int ?? 0
                out = countObj["output_tokens"] as? Int ?? 0
                cached = countObj["cached_input_tokens"] as? Int ?? 0
            } else if let usageObj = json["usage"] as? [String: Any] {
                inp = usageObj["input_tokens"] as? Int ?? 0
                out = usageObj["output_tokens"] as? Int ?? 0
                cached = usageObj["cached_input_tokens"] as? Int ?? 0
            } else {
                inp = json["input_tokens"] as? Int ?? 0
                out = json["output_tokens"] as? Int ?? 0
                cached = json["cached_input_tokens"] as? Int ?? 0
            }
            
            if isToday {
                stats.inputTokensToday += inp
                stats.outputTokensToday += out
                stats.cachedTokensToday += cached
            }
            stats.inputTokensMonth += inp
            stats.outputTokensMonth += out
            stats.cachedTokensMonth += cached
        }
    }
    
    // MARK: - Scan Claude Code Sessions (~/.claude/projects)
    public func scanClaudeSessions() -> LocalTokenStats? {
        let home = fileManager.homeDirectoryForCurrentUser
        let claudeProjectsDir = home.appendingPathComponent(".claude/projects")
        
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: claudeProjectsDir.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        
        let now = Date()
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) ?? now
        
        var stats = LocalTokenStats()
        
        guard let enumerator = fileManager.enumerator(
            at: claudeProjectsDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        var foundAny = false
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }
            guard let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modDate = values.contentModificationDate,
                  modDate >= thirtyDaysAgo else {
                continue
            }
            
            foundAny = true
            let isToday = modDate >= startOfToday
            if isToday {
                stats.sessionsCountToday += 1
            }
            stats.sessionsCountMonth += 1
            
            parseClaudeJsonlFile(at: fileURL, isToday: isToday, stats: &stats)
        }
        
        guard foundAny else { return nil }
        
        stats.totalTokensToday = stats.inputTokensToday + stats.outputTokensToday
        stats.totalTokensMonth = stats.inputTokensMonth + stats.outputTokensMonth
        
        // Anthropic Claude 3.5 Sonnet pricing: ~$3.00/M input, ~$15.00/M output, ~$0.30/M cache read
        stats.estimatedCostTodayUSD = (Double(stats.inputTokensToday) * 0.000003) +
                                      (Double(stats.outputTokensToday) * 0.000015) +
                                      (Double(stats.cachedTokensToday) * 0.0000003)
        
        stats.estimatedCostMonthUSD = (Double(stats.inputTokensMonth) * 0.000003) +
                                      (Double(stats.outputTokensMonth) * 0.000015) +
                                      (Double(stats.cachedTokensMonth) * 0.0000003)
        
        return stats
    }
    
    private func parseClaudeJsonlFile(at url: URL, isToday: Bool, stats: inout LocalTokenStats) {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return
        }
        
        for line in content.split(separator: "\n") {
            guard line.contains("usage") || line.contains("input_tokens") else {
                continue
            }
            
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }
            
            var inp = 0
            var out = 0
            var cached = 0
            
            // Format: { "message": { "usage": { "input_tokens": 123, "output_tokens": 45, "cache_read_input_tokens": 100 } } }
            if let msg = json["message"] as? [String: Any],
               let usage = msg["usage"] as? [String: Any] {
                inp = usage["input_tokens"] as? Int ?? 0
                out = usage["output_tokens"] as? Int ?? 0
                cached = usage["cache_read_input_tokens"] as? Int ?? 0
            } else if let usage = json["usage"] as? [String: Any] {
                inp = usage["input_tokens"] as? Int ?? 0
                out = usage["output_tokens"] as? Int ?? 0
                cached = usage["cache_read_input_tokens"] as? Int ?? 0
            }
            
            if isToday {
                stats.inputTokensToday += inp
                stats.outputTokensToday += out
                stats.cachedTokensToday += cached
            }
            stats.inputTokensMonth += inp
            stats.outputTokensMonth += out
            stats.cachedTokensMonth += cached
        }
    }
    
    // MARK: - Auto-Discover Any Local AI Session
    public func hasCodexLogs() -> Bool {
        let p = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex/sessions").path
        return fileManager.fileExists(atPath: p)
    }
    
    public func hasClaudeLogs() -> Bool {
        let p = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects").path
        return fileManager.fileExists(atPath: p)
    }
}
