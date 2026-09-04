//
//  AIProvider.swift
//  Usage Notch
//

import SwiftUI

public enum AIProviderType: String, CaseIterable, Codable, Identifiable {
    case claude = "Claude"
    case cursor = "Cursor"
    case antigravity = "Antigravity"
    case claudeCode = "Claude Code"
    case kiro = "Kiro"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .cursor: return "Cursor"
        case .antigravity: return "Antigravity"
        case .claudeCode: return "Claude Code"
        case .kiro: return "Kiro"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .claude: return "Anthropic API & Pro Quota"
        case .cursor: return "Fast & Slow Requests (Cursor API)"
        case .antigravity: return "Autonomous Coding & OpenRouter"
        case .claudeCode: return "Terminal Agent Token Budget"
        case .kiro: return "Dev Assistant & Custom API"
        }
    }
    
    public var defaultAccentColor: Color {
        switch self {
        case .claude: return Color(red: 0.94, green: 0.45, blue: 0.28) // Warm Anthropic terracotta / orange
        case .cursor: return Color(red: 0.16, green: 0.65, blue: 0.98) // Bright Cursor blue
        case .antigravity: return Color(red: 0.95, green: 0.80, blue: 0.20) // Deepmind gold/yellow
        case .claudeCode: return Color(red: 0.20, green: 0.85, blue: 0.65) // Terminal cyan/mint
        case .kiro: return Color(red: 0.75, green: 0.45, blue: 0.95) // Purple accent
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
    
    public init(
        id: AIProviderType,
        isEnabled: Bool = true,
        connectionMode: ConnectionMode = .api,
        apiKeyOrToken: String = "",
        customEndpoint: String = "",
        lastSyncStatus: String = "No configurado",
        primaryLabel: String = "Current session",
        primaryUsedPercent: Double = 50.0,
        primaryResetIntervalMinutes: Int = 300,
        secondaryLabel: String = "All models",
        secondaryUsedPercent: Double = 15.0,
        currentCount: Double = 73,
        maxCount: Double = 100,
        unitName: String = "%"
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
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86400 * 4)
        self.currentCount = currentCount
        self.maxCount = maxCount
        self.unitName = unitName
    }
    
    public var primaryTimeRemainingString: String {
        let remaining = primaryResetDate.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Reset pending"
        }
        let minutes = Int(remaining / 60)
        if minutes < 60 {
            return "Resets in \(max(1, minutes)) min"
        }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        if remainingMins == 0 {
            return "Resets in \(hours)h"
        }
        return "Resets in \(hours)h \(remainingMins)m"
    }
    
    public var secondaryResetString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return "Resets \(formatter.string(from: secondaryResetDate))"
    }
}
