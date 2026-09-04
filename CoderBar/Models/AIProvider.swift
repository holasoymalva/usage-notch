//
//  AIProvider.swift
//  Usage Notch
//

import SwiftUI

public enum AIProviderType: String, CaseIterable, Codable, Identifiable {
    case antigravity = "Antigravity"
    case codex = "Codex"
    case copilot = "Copilot"
    case claude = "Claude"
    case cursor = "Cursor"
    case claudeCode = "Claude Code"
    case kiro = "Kiro"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .antigravity: return "Antigravity"
        case .codex: return "Codex"
        case .copilot: return "Copilot"
        case .claude: return "Claude"
        case .cursor: return "Cursor"
        case .claudeCode: return "Claude Code"
        case .kiro: return "Kiro"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .antigravity: return "Google Antigravity & Agent Studio"
        case .codex: return "OpenAI Codex & Developer Platform"
        case .copilot: return "GitHub Copilot Workspace & Agent"
        case .claude: return "Anthropic API & Pro Quota"
        case .cursor: return "Fast & Slow Requests (Cursor API)"
        case .claudeCode: return "Terminal Agent Token Budget"
        case .kiro: return "Dev Assistant & Custom API"
        }
    }
    
    public var defaultAccentColor: Color {
        switch self {
        case .antigravity, .codex, .copilot:
            return Color(red: 0.05, green: 0.90, blue: 0.48) // Electric emerald green
        case .claude:
            return Color(red: 0.94, green: 0.45, blue: 0.28) // Warm Anthropic terracotta / orange
        case .cursor:
            return Color(red: 0.16, green: 0.65, blue: 0.98) // Bright Cursor blue
        case .claudeCode:
            return Color(red: 0.20, green: 0.85, blue: 0.65) // Terminal cyan/mint
        case .kiro:
            return Color(red: 0.75, green: 0.45, blue: 0.95) // Purple accent
        }
    }
}

public enum ConnectionMode: String, CaseIterable, Codable, Identifiable {
    case api = "API en Vivo (Automático)"
    case manual = "Cuota Manual / Plan Pro"
    
    public var id: String { rawValue }
}

public struct ProviderUsage: Codable, Identifiable {
    public var id: AIProviderType
    public var isEnabled: Bool
    
    // Connection Settings
    public var connectionMode: ConnectionMode
    public var apiKeyOrToken: String
    public var customEndpoint: String
    public var lastSyncStatus: String
    
    // Primary metric (e.g. Current session or Fast requests)
    public var primaryLabel: String
    public var primaryUsedPercent: Double // 0.0 - 100.0
    public var primaryResetDate: Date
    public var primaryResetIntervalMinutes: Int
    
    // Secondary metric (e.g. All models or Monthly allowance)
    public var secondaryLabel: String
    public var secondaryUsedPercent: Double // 0.0 - 100.0
    public var secondaryResetDate: Date
    
    // Optional absolute counters (e.g. 146 / 500 fast requests or $14.20)
    public var currentCount: Double
    public var maxCount: Double
    public var unitName: String
    
    // Optional token stats (e.g. for Codex)
    public var tokensToday: String?
    public var tokensMonth: String?
    
    // Remaining percentages (mockup shows % Remaining)
    public var primaryRemainingPercent: Double {
        get { max(0.0, min(100.0, 100.0 - primaryUsedPercent)) }
        set { primaryUsedPercent = max(0.0, min(100.0, 100.0 - newValue)) }
    }
    
    public var secondaryRemainingPercent: Double {
        get { max(0.0, min(100.0, 100.0 - secondaryUsedPercent)) }
        set { secondaryUsedPercent = max(0.0, min(100.0, 100.0 - newValue)) }
    }
    
    public init(
        id: AIProviderType,
        isEnabled: Bool = true,
        connectionMode: ConnectionMode = .api,
        apiKeyOrToken: String = "",
        customEndpoint: String = "",
        lastSyncStatus: String = "No configurado",
        primaryLabel: String = "Current session",
        primaryUsedPercent: Double = 0.0, // Default 0% used = 100% remaining
        primaryResetIntervalMinutes: Int = 300,
        secondaryLabel: String = "Weekly",
        secondaryUsedPercent: Double = 1.0, // Default 1% used = 99% remaining
        currentCount: Double = 100,
        maxCount: Double = 100,
        unitName: String = "%",
        tokensToday: String? = nil,
        tokensMonth: String? = nil
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.connectionMode = connectionMode
        self.apiKeyOrToken = apiKeyOrToken
        self.customEndpoint = customEndpoint
        self.lastSyncStatus = lastSyncStatus
        self.primaryLabel = primaryLabel
        self.primaryUsedPercent = primaryUsedPercent
        self.primaryResetIntervalMinutes = primaryResetIntervalMinutes
        self.primaryResetDate = Date().addingTimeInterval(TimeInterval(primaryResetIntervalMinutes * 60))
        self.secondaryLabel = secondaryLabel
        self.secondaryUsedPercent = secondaryUsedPercent
        self.secondaryResetDate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 23, minute: 52),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86400 * 4)
        self.currentCount = currentCount
        self.maxCount = maxCount
        self.unitName = unitName
        self.tokensToday = tokensToday
        self.tokensMonth = tokensMonth
    }
    
    public var headerResetString: String {
        let remaining = primaryResetDate.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Resets soon"
        }
        let totalMinutes = Int(remaining / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "Resets in \(hours)h \(minutes)m"
        } else {
            return "Resets in \(minutes)m"
        }
    }
    
    public var primaryResetTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Resets today \(formatter.string(from: primaryResetDate))"
    }
    
    public var secondaryResetTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return "Resets \(formatter.string(from: secondaryResetDate))"
    }
    
    public var primaryTimeRemainingString: String {
        return headerResetString
    }
    
    public var secondaryResetString: String {
        return secondaryResetTimeString
    }
}
