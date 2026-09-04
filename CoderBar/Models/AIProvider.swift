//
//  AIProvider.swift
//  Usage Notch
//

import SwiftUI

public enum AuthMethod: String, Codable, CaseIterable {
    case oauth = "OAuth"
    case apiKey = "API key"
    case cookies = "Cookies"
    case cookiesGo = "Cookies + Go"
    case local = "Local"
    case cli = "CLI"
    case bearerLocal = "Bearer / Local"
    case token = "Token"
    case gcloud = "gcloud"
    case apiKeyCookies = "API key + Cookies"
    case virtualKey = "Virtual key"
    case deviceFlow = "Device flow"
    case custom = "guía de autoría ↗"
}

public enum ProviderCategory: String, Codable, CaseIterable, Identifiable {
    case all = "Todos"
    case active = "Activos"
    case llm = "Modelos LLM"
    case ide = "IDEs y Editores"
    case agent = "Agentes"
    case infra = "Infraestructura"
    
    public var id: String { rawValue }
}

public enum AIProviderType: String, CaseIterable, Codable, Identifiable {
    // Row 1
    case codex = "Codex"
    case claude = "Claude"
    case cursor = "Cursor"
    case opencode = "OpenCode"
    case alibaba = "Alibaba"
    
    // Row 2
    case alibabaToken = "Alibaba Token"
    case gemini = "Gemini"
    case antigravity = "Antigravity"
    case droid = "Droid"
    case copilot = "Copilot"
    
    // Row 3
    case devin = "Devin"
    case zai = "z.ai"
    case minimax = "MiniMax"
    case kimi = "Kimi"
    case kilo = "Kilo"
    
    // Row 4
    case kiro = "Kiro"
    case vertexAI = "Vertex AI"
    case augment = "Augment"
    case amp = "Amp"
    case ollama = "Ollama"
    
    // Row 5
    case synthetic = "Synthetic"
    case jetbrains = "JetBrains AI"
    case warp = "Warp"
    case elevenlabs = "ElevenLabs"
    case openrouter = "OpenRouter"
    
    // Row 6
    case litellm = "LiteLLM"
    case perplexity = "Perplexity"
    case abacus = "Abacus AI"
    case mistral = "Mistral"
    case deepseek = "DeepSeek"
    
    // Row 7
    case deepinfra = "DeepInfra"
    case t3chat = "T3 Chat"
    case codebuff = "Codebuff"
    case poe = "Poe"
    case chutes = "Chutes"
    
    // Row 8
    case zed = "Zed"
    case claudeCode = "Claude Code"
    case custom = "Tu proveedor"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        return rawValue
    }
    
    public var authMethod: AuthMethod {
        switch self {
        case .codex, .claude, .gemini:
            return .oauth
        case .cursor, .alibaba, .alibabaToken, .droid, .amp, .perplexity, .abacus, .mistral, .t3chat:
            return .cookies
        case .opencode:
            return .cookiesGo
        case .antigravity, .jetbrains, .zed:
            return .local
        case .copilot:
            return .deviceFlow
        case .devin:
            return .bearerLocal
        case .kiro, .augment:
            return .cli
        case .vertexAI:
            return .gcloud
        case .kimi:
            return .token
        case .ollama:
            return .apiKeyCookies
        case .litellm:
            return .virtualKey
        case .custom:
            return .custom
        default:
            return .apiKey
        }
    }
    
    public var category: ProviderCategory {
        switch self {
        case .codex, .claude, .gemini, .alibaba, .alibabaToken, .minimax, .kimi, .ollama, .perplexity, .abacus, .mistral, .deepseek, .poe:
            return .llm
        case .cursor, .opencode, .kilo, .augment, .jetbrains, .warp, .zed:
            return .ide
        case .antigravity, .droid, .copilot, .devin, .kiro, .amp, .t3chat, .codebuff, .claudeCode:
            return .agent
        case .zai, .vertexAI, .synthetic, .elevenlabs, .openrouter, .litellm, .deepinfra, .chutes:
            return .infra
        case .custom:
            return .all
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
        case .deepseek: return "DeepSeek V3 / R1 API"
        case .gemini: return "Google Gemini Pro & Flash"
        case .ollama: return "Ollama Local & Cloud"
        case .openrouter: return "OpenRouter Unified API"
        case .perplexity: return "Perplexity Pro & API"
        case .mistral: return "Mistral Large & Codestral"
        case .jetbrains: return "JetBrains AI Assistant"
        case .warp: return "Warp Terminal Agent"
        case .zed: return "Zed Editor AI"
        case .devin: return "Cognition Devin Autonomous Agent"
        case .custom: return "Proxy o endpoint personalizado"
        default: return "\(displayName) Provider API"
        }
    }
    
    public var defaultAccentColor: Color {
        switch self {
        case .antigravity, .codex, .copilot:
            return Color(red: 0.05, green: 0.90, blue: 0.48)
        case .claude:
            return Color(red: 0.94, green: 0.45, blue: 0.28)
        case .cursor:
            return Color(red: 0.16, green: 0.65, blue: 0.98)
        case .deepseek:
            return Color(red: 0.22, green: 0.55, blue: 0.98)
        case .gemini:
            return Color(red: 0.35, green: 0.60, blue: 0.98)
        case .mistral:
            return Color(red: 0.98, green: 0.45, blue: 0.15)
        case .ollama:
            return Color(white: 0.90)
        default:
            return Color(red: 0.05, green: 0.90, blue: 0.48)
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
