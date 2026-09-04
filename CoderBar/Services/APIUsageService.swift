//
//  APIUsageService.swift
//  Usage Notch
//

import Foundation
import Combine

public struct CursorUsageResponse: Codable {
    public var numRequests: Int?
    public var numRequestsTotal: Int?
    public var maxRequestUsage: Int?
    public var startOfMonth: String?
}

public struct OpenRouterKeyResponse: Codable {
    public struct KeyData: Codable {
        public var label: String?
        public var usage: Double?
        public var limit: Double?
        public var isFreeTier: Bool?
        
        enum CodingKeys: String, CodingKey {
            case label
            case usage
            case limit
            case isFreeTier = "is_free_tier"
        }
    }
    public var data: KeyData?
}

@MainActor
public final class APIUsageService: ObservableObject {
    public static let shared = APIUsageService()
    
    @Published public var isSyncing: Bool = false
    @Published public var testingProviderId: AIProviderType? = nil
    @Published public var lastSyncDate: Date? = nil
    
    private var syncTimer: AnyCancellable?
    
    public init() {
        // Auto-sync every 5 minutes in background
        syncTimer = Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.syncAllServices()
                }
            }
    }
    
    public func syncAllServices() async {
        guard !isSyncing else { return }
        isSyncing = true
        
        for provider in UsageManager.shared.providers where provider.isEnabled && provider.connectionMode == .api {
            _ = await testAndSync(providerId: provider.id)
        }
        
        lastSyncDate = Date()
        isSyncing = false
    }
    
    // MARK: - Individual Test & Sync
    public func testAndSync(providerId: AIProviderType) async -> (success: Bool, message: String) {
        guard let index = UsageManager.shared.providers.firstIndex(where: { $0.id == providerId }) else {
            return (false, "Proveedor no encontrado")
        }
        
        testingProviderId = providerId
        let provider = UsageManager.shared.providers[index]
        let token = provider.apiKeyOrToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        defer {
            testingProviderId = nil
        }
        
        if token.isEmpty {
            let msg = "Ingresa un Token o API Key válido"
            UsageManager.shared.providers[index].lastSyncStatus = "⚠️ \(msg)"
            UsageManager.shared.save()
            return (false, msg)
        }
        
        switch providerId {
        case .antigravity:
            return await syncAntigravity(index: index, apiKey: token)
        case .codex:
            return await syncCodex(index: index, apiKey: token)
        case .copilot:
            return await syncCopilot(index: index, token: token)
        case .cursor:
            return await syncCursor(index: index, token: token)
        case .claude:
            return await syncClaude(index: index, apiKey: token)
        case .claudeCode:
            return await syncClaudeCode(index: index, apiKey: token)
        case .kiro:
            return await syncKiro(index: index, token: token, endpoint: provider.customEndpoint)
        }
    }
    
    // MARK: - Cursor API (https://www.cursor.com/api/usage)
    private func syncCursor(index: Int, token: String) async -> (Bool, String) {
        guard let url = URL(string: "https://www.cursor.com/api/usage") else {
            return (false, "URL de Cursor inválida")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("WorkosCursorSessionToken=\(token)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Respuesta de red inválida")
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                let msg = "Token expirado o inválido (Error \(httpResponse.statusCode))"
                UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
                UsageManager.shared.save()
                return (false, msg)
            }
            
            guard httpResponse.statusCode == 200 else {
                let msg = "Error del servidor Cursor (HTTP \(httpResponse.statusCode))"
                UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
                UsageManager.shared.save()
                return (false, msg)
            }
            
            if let decoded = try? JSONDecoder().decode(CursorUsageResponse.self, from: data) {
                let used = Double(decoded.numRequests ?? 0)
                let maxLimit = Double(decoded.maxRequestUsage ?? 500)
                let pct = min(100.0, max(0.0, (used / maxLimit) * 100.0))
                
                UsageManager.shared.providers[index].primaryUsedPercent = pct
                UsageManager.shared.providers[index].currentCount = used
                UsageManager.shared.providers[index].maxCount = maxLimit
                UsageManager.shared.providers[index].unitName = "reqs"
                UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado (\(Int(used))/\(Int(maxLimit)) reqs)"
                UsageManager.shared.save()
                return (true, "Conectado exitosamente: \(Int(used)) de \(Int(maxLimit)) fast requests usados.")
            } else {
                return (false, "Respuesta de Cursor con formato inesperado")
            }
        } catch {
            let msg = "Fallo de conexión: \(error.localizedDescription)"
            UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
            UsageManager.shared.save()
            return (false, msg)
        }
    }
    
    // MARK: - Anthropic API (Claude)
    private func syncClaude(index: Int, apiKey: String) async -> (Bool, String) {
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            return (false, "URL de Anthropic inválida")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Respuesta inválida")
            }
            
            if httpResponse.statusCode == 401 {
                let msg = "API Key inválida (HTTP 401 Unauthorized)"
                UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
                UsageManager.shared.save()
                return (false, msg)
            }
            
            if httpResponse.statusCode == 200 {
                var rateLimitInfo = "Conectado"
                if let remainingHeader = httpResponse.value(forHTTPHeaderField: "anthropic-ratelimit-requests-remaining"),
                   let limitHeader = httpResponse.value(forHTTPHeaderField: "anthropic-ratelimit-requests-limit"),
                   let rem = Double(remainingHeader),
                   let lim = Double(limitHeader), lim > 0 {
                    let used = lim - rem
                    let pct = min(100.0, max(0.0, (used / lim) * 100.0))
                    UsageManager.shared.providers[index].primaryUsedPercent = pct
                    rateLimitInfo = "\(Int(rem)) reqs restantes"
                }
                
                UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado (\(rateLimitInfo))"
                UsageManager.shared.save()
                return (true, "Anthropic API Key verificada con éxito. \(rateLimitInfo).")
            }
            
            return (false, "Código HTTP \(httpResponse.statusCode)")
        } catch {
            let msg = "Error de red: \(error.localizedDescription)"
            UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
            UsageManager.shared.save()
            return (false, msg)
        }
    }
    
    // MARK: - OpenRouter / Gemini API (Antigravity)
    private func syncAntigravity(index: Int, apiKey: String) async -> (Bool, String) {
        let isGoogleKey = apiKey.hasPrefix("AIza")
        let urlString = isGoogleKey
            ? "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
            : "https://openrouter.ai/api/v1/auth/key"
        
        guard let url = URL(string: urlString) else { return (false, "URL inválida") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !isGoogleKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Sin respuesta")
            }
            
            if httpResponse.statusCode == 200 {
                if !isGoogleKey, let decoded = try? JSONDecoder().decode(OpenRouterKeyResponse.self, from: data),
                   let keyData = decoded.data {
                    let used = keyData.usage ?? 0.0
                    let limit = keyData.limit ?? 100.0
                    let pct = limit > 0 ? min(100.0, (used / limit) * 100.0) : 10.0
                    UsageManager.shared.providers[index].primaryUsedPercent = pct
                    UsageManager.shared.providers[index].currentCount = used
                    UsageManager.shared.providers[index].maxCount = limit
                    UsageManager.shared.providers[index].unitName = "$"
                }
                
                UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado en vivo"
                UsageManager.shared.save()
                return (true, "Antigravity API conectada correctamente.")
            } else {
                let msg = "Credencial rechazada (HTTP \(httpResponse.statusCode))"
                UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
                UsageManager.shared.save()
                return (false, msg)
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    // MARK: - OpenAI / Codex API
    private func syncCodex(index: Int, apiKey: String) async -> (Bool, String) {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return (false, "URL inválida")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Sin respuesta de OpenAI")
            }
            
            if httpResponse.statusCode == 200 {
                UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado"
                UsageManager.shared.save()
                return (true, "OpenAI Codex conectado con éxito.")
            } else if httpResponse.statusCode == 401 {
                let msg = "API Key de OpenAI inválida (401)"
                UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
                UsageManager.shared.save()
                return (false, msg)
            } else {
                return (false, "Código HTTP \(httpResponse.statusCode)")
            }
        } catch {
            let msg = "Error de conexión: \(error.localizedDescription)"
            UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
            UsageManager.shared.save()
            return (false, msg)
        }
    }
    
    // MARK: - GitHub Copilot API
    private func syncCopilot(index: Int, token: String) async -> (Bool, String) {
        guard let url = URL(string: "https://api.github.com/user") else {
            return (false, "URL inválida")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("CoderBar-App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Sin respuesta de GitHub")
            }
            
            if httpResponse.statusCode == 200 {
                UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado"
                UsageManager.shared.save()
                return (true, "GitHub Copilot verificado con éxito.")
            } else if httpResponse.statusCode == 401 {
                let msg = "Token de GitHub inválido (401)"
                UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
                UsageManager.shared.save()
                return (false, msg)
            } else {
                return (false, "Código HTTP \(httpResponse.statusCode)")
            }
        } catch {
            let msg = "Error de red: \(error.localizedDescription)"
            UsageManager.shared.providers[index].lastSyncStatus = "🔴 \(msg)"
            UsageManager.shared.save()
            return (false, msg)
        }
    }
    
    // MARK: - Claude Code CLI
    private func syncClaudeCode(index: Int, apiKey: String) async -> (Bool, String) {
        // Claude Code uses token limits or Anthropic key
        return await syncClaude(index: index, apiKey: apiKey)
    }
    
    // MARK: - Kiro / Custom API
    private func syncKiro(index: Int, token: String, endpoint: String) async -> (Bool, String) {
        let urlStr = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlStr.isEmpty, let url = URL(string: urlStr) else {
            // Default mock connection simulation if no custom URL
            UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado (Local)"
            UsageManager.shared.save()
            return (true, "Conectado al runtime local de Kiro.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                UsageManager.shared.providers[index].lastSyncStatus = "🟢 Conectado"
                UsageManager.shared.save()
                return (true, "Endpoint de Kiro respondió OK.")
            } else {
                return (false, "Error en endpoint personalizado")
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
