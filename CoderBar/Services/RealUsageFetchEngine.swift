//
//  RealUsageFetchEngine.swift
//  Usage Notch
//

import Foundation

public struct RealUsageResult {
    public var success: Bool
    public var message: String
    public var lastSyncStatus: String
    public var hasLiveMetrics: Bool
    public var primaryLabel: String?
    public var primaryUsedPercent: Double?
    public var primaryResetDate: Date?
    public var primaryResetIntervalMinutes: Int?
    public var secondaryLabel: String?
    public var secondaryUsedPercent: Double?
    public var secondaryResetDate: Date?
    public var currentCount: Double?
    public var maxCount: Double?
    public var unitName: String?
    public var tokensToday: String?
    public var tokensMonth: String?
    
    public init(
        success: Bool,
        message: String,
        lastSyncStatus: String,
        hasLiveMetrics: Bool = false,
        primaryLabel: String? = nil,
        primaryUsedPercent: Double? = nil,
        primaryResetDate: Date? = nil,
        primaryResetIntervalMinutes: Int? = nil,
        secondaryLabel: String? = nil,
        secondaryUsedPercent: Double? = nil,
        secondaryResetDate: Date? = nil,
        currentCount: Double? = nil,
        maxCount: Double? = nil,
        unitName: String? = nil,
        tokensToday: String? = nil,
        tokensMonth: String? = nil
    ) {
        self.success = success
        self.message = message
        self.lastSyncStatus = lastSyncStatus
        self.hasLiveMetrics = hasLiveMetrics
        self.primaryLabel = primaryLabel
        self.primaryUsedPercent = primaryUsedPercent
        self.primaryResetDate = primaryResetDate
        self.primaryResetIntervalMinutes = primaryResetIntervalMinutes
        self.secondaryLabel = secondaryLabel
        self.secondaryUsedPercent = secondaryUsedPercent
        self.secondaryResetDate = secondaryResetDate
        self.currentCount = currentCount
        self.maxCount = maxCount
        self.unitName = unitName
        self.tokensToday = tokensToday
        self.tokensMonth = tokensMonth
    }
}

// Delegate that permits localhost / 127.0.0.1 self-signed TLS certificates (used by Antigravity local language server)
final class LocalhostInsecureSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust,
           let host = challenge.protectionSpace.host as String?,
           (host == "127.0.0.1" || host == "localhost") {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

public actor RealUsageFetchEngine {
    public static let shared = RealUsageFetchEngine()
    
    private let urlSession: URLSession
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 15
        self.urlSession = URLSession(configuration: config, delegate: LocalhostInsecureSessionDelegate(), delegateQueue: nil)
    }
    
    // MARK: - Main Dispatcher
    public func fetchUsage(for provider: ProviderUsage) async -> RealUsageResult {
        let token = provider.apiKeyOrToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = provider.customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch provider.id {
        case .deepseek:
            return await fetchDeepSeek(token: token)
            
        case .openrouter:
            return await fetchOpenRouter(token: token)
            
        case .elevenlabs:
            return await fetchElevenLabs(token: token)
            
        case .cursor:
            return await fetchCursor(token: token, customEndpoint: endpoint)
            
        case .litellm:
            return await fetchLiteLLM(token: token, customEndpoint: endpoint)
            
        case .antigravity:
            return await fetchAntigravity(token: token, customEndpoint: endpoint)
            
        case .ollama:
            return await fetchOllama(customEndpoint: endpoint)
            
        case .codex:
            return await fetchOpenAICodex(token: token)
            
        case .claude, .claudeCode:
            return await fetchClaude(token: token)
            
        case .copilot:
            return await fetchCopilot(token: token)
            
        case .zed:
            return await fetchZed(token: token)
            
        case .devin:
            return await fetchDevin(token: token, customEndpoint: endpoint)
            
        case .kiro:
            return await fetchKiro(token: token, customEndpoint: endpoint)
            
        case .perplexity:
            return await fetchPerplexity(token: token)
            
        case .mistral:
            return await fetchMistral(token: token)
            
        default:
            return await fetchGenericProvider(provider: provider, token: token, endpoint: endpoint)
        }
    }
    
    // MARK: - 1. DeepSeek (/user/balance)
    private func fetchDeepSeek(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(
                success: false,
                message: "Por favor ingresa tu API Key de DeepSeek (sk-...)",
                lastSyncStatus: "⚠️ Requiere API Key"
            )
        }
        
        guard let url = URL(string: "https://api.deepseek.com/user/balance") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error de URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Respuesta de red inválida", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "API Key de DeepSeek inválida o revocada (401)", lastSyncStatus: "🔴 API Key no autorizada")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "DeepSeek respondió con código HTTP \(http.statusCode)", lastSyncStatus: "🔴 Error HTTP \(http.statusCode)")
            }
            
            struct DeepSeekBalanceInfo: Codable {
                let currency: String?
                let total_balance: String?
                let granted_balance: String?
                let topped_up_balance: String?
            }
            struct DeepSeekResponse: Codable {
                let is_available: Bool?
                let balance_infos: [DeepSeekBalanceInfo]?
            }
            
            let decoded = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
            if let first = decoded.balance_infos?.first {
                let currency = first.currency ?? "USD"
                let totalStr = first.total_balance ?? "0.00"
                let grantedStr = first.granted_balance ?? "0.00"
                let toppedStr = first.topped_up_balance ?? "0.00"
                let totalVal = Double(totalStr) ?? 0.0
                let grantedVal = Double(grantedStr) ?? 0.0
                let toppedVal = Double(toppedStr) ?? 0.0
                let totalMax = max(totalVal, grantedVal + toppedVal)
                let remainingPct = totalMax > 0 ? min(100.0, max(0.0, (totalVal / totalMax) * 100.0)) : (totalVal > 0 ? 100.0 : 0.0)
                let usedPct = 100.0 - remainingPct
                
                return RealUsageResult(
                    success: true,
                    message: "Saldo de DeepSeek sincronizado: $\(totalStr) \(currency)",
                    lastSyncStatus: "🟢 Saldo: $\(totalStr) \(currency)",
                    hasLiveMetrics: true,
                    primaryLabel: "Saldo Disponible",
                    primaryUsedPercent: usedPct,
                    currentCount: totalVal,
                    maxCount: totalMax > 0 ? totalMax : 100.0,
                    unitName: "$",
                    tokensToday: "Total: $\(totalStr) \(currency)",
                    tokensMonth: "Recargado: $\(toppedStr) · Donado: $\(grantedStr)"
                )
            } else {
                return RealUsageResult(success: false, message: "Formato inesperado en respuesta de DeepSeek", lastSyncStatus: "🟠 Respuesta incompleta")
            }
        } catch {
            return RealUsageResult(success: false, message: "Error al conectar con DeepSeek: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 2. OpenRouter (/api/v1/auth/key)
    private func fetchOpenRouter(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu API Key de OpenRouter (sk-or-...)", lastSyncStatus: "⚠️ Requiere API Key")
        }
        
        guard let url = URL(string: "https://openrouter.ai/api/v1/auth/key") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta de red", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "API Key de OpenRouter inválida (401)", lastSyncStatus: "🔴 Key inválida")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "OpenRouter HTTP \(http.statusCode)", lastSyncStatus: "🔴 Error \(http.statusCode)")
            }
            
            struct ORKeyData: Codable {
                let label: String?
                let usage: Double?
                let limit: Double?
                let is_free_tier: Bool?
                let rate_limit: RateLimit?
                
                struct RateLimit: Codable {
                    let requests: Int?
                    let interval: String?
                }
            }
            struct ORResponse: Codable {
                let data: ORKeyData?
            }
            
            let res = try JSONDecoder().decode(ORResponse.self, from: data)
            if let keyData = res.data {
                let usage = keyData.usage ?? 0.0
                let limit = keyData.limit ?? 0.0
                let usedPct: Double
                if limit > 0 {
                    usedPct = min(100.0, max(0.0, (usage / limit) * 100.0))
                } else {
                    usedPct = 0.0
                }
                
                let limitStr = limit > 0 ? "$\(String(format: "%.2f", limit))" : "Sin límite"
                let rateLimitDesc = keyData.rate_limit?.requests != nil ? " (\(keyData.rate_limit!.requests!) reqs/\(keyData.rate_limit!.interval ?? "s"))" : ""
                
                return RealUsageResult(
                    success: true,
                    message: "OpenRouter sincronizado: $\(String(format: "%.2f", usage)) gastados de \(limitStr)",
                    lastSyncStatus: "🟢 Gasto: $\(String(format: "%.2f", usage)) / \(limitStr)",
                    hasLiveMetrics: true,
                    primaryLabel: "Presupuesto API Key",
                    primaryUsedPercent: usedPct,
                    currentCount: usage,
                    maxCount: limit > 0 ? limit : 100.0,
                    unitName: "$",
                    tokensToday: "Uso actual: $\(String(format: "%.2f", usage)) USD",
                    tokensMonth: "Límite: \(limitStr)\(rateLimitDesc)"
                )
            } else {
                return RealUsageResult(success: false, message: "Datos no encontrados en OpenRouter", lastSyncStatus: "🟠 Respuesta incompleta")
            }
        } catch {
            return RealUsageResult(success: false, message: "Error de conexión: \(error.localizedDescription)", lastSyncStatus: "🔴 Fallo de conexión")
        }
    }
    
    // MARK: - 3. ElevenLabs (/v1/user/subscription)
    private func fetchElevenLabs(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu API Key de ElevenLabs", lastSyncStatus: "⚠️ Requiere API Key")
        }
        
        guard let url = URL(string: "https://api.elevenlabs.io/v1/user/subscription") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "API Key de ElevenLabs inválida (401)", lastSyncStatus: "🔴 Key inválida")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "ElevenLabs HTTP \(http.statusCode)", lastSyncStatus: "🔴 Error \(http.statusCode)")
            }
            
            struct ElevenSubscription: Codable {
                let tier: String?
                let character_count: Int?
                let character_limit: Int?
                let next_character_count_reset_unix: Int?
                let status: String?
            }
            
            let sub = try JSONDecoder().decode(ElevenSubscription.self, from: data)
            let used = Double(sub.character_count ?? 0)
            let limit = Double(sub.character_limit ?? 10000)
            let usedPct = limit > 0 ? min(100.0, max(0.0, (used / limit) * 100.0)) : 0.0
            
            let resetDate: Date
            if let unix = sub.next_character_count_reset_unix, unix > 0 {
                resetDate = Date(timeIntervalSince1970: TimeInterval(unix))
            } else {
                resetDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            }
            
            let tierName = sub.tier?.capitalized ?? "Plan"
            let usedInt = sub.character_count ?? 0
            let limitInt = sub.character_limit ?? 0
            
            return RealUsageResult(
                success: true,
                message: "ElevenLabs sincronizado (\(usedInt)/\(limitInt) caracteres)",
                lastSyncStatus: "🟢 \(usedInt)/\(limitInt) chars",
                hasLiveMetrics: true,
                primaryLabel: "Caracteres del Plan",
                primaryUsedPercent: usedPct,
                primaryResetDate: resetDate,
                currentCount: used,
                maxCount: limit,
                unitName: "chars",
                tokensToday: "Consumidos: \(usedInt) chars",
                tokensMonth: "Límite: \(limitInt) chars (Tier: \(tierName))"
            )
        } catch {
            return RealUsageResult(success: false, message: "Error ElevenLabs: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 4. Cursor API (/api/usage)
    private func fetchCursor(token: String, customEndpoint: String = "") async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(
                success: false,
                message: "Pega tu Cookie WorkosCursorSessionToken en las preferencias de Cursor",
                lastSyncStatus: "⚠️ Requiere Cookie de Sesión"
            )
        }
        
        var candidateURLs: [URL] = []
        if !customEndpoint.isEmpty, let custom = URL(string: customEndpoint) {
            candidateURLs.append(custom)
        }
        if let apex = URL(string: "https://cursor.com/api/usage") {
            candidateURLs.append(apex)
        }
        if let www = URL(string: "https://www.cursor.com/api/usage") {
            candidateURLs.append(www)
        }
        if let api2 = URL(string: "https://api2.cursor.sh/api/usage") {
            candidateURLs.append(api2)
        }
        
        var cookieHeader = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cookieHeader.contains("WorkosCursorSessionToken=") {
            cookieHeader = "WorkosCursorSessionToken=\(cookieHeader)"
        }
        
        var lastErrorMsg = "No se pudo conectar a los servidores de Cursor"
        
        for url in candidateURLs {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 8
            
            do {
                let (data, response) = try await urlSession.data(for: request)
                guard let http = response as? HTTPURLResponse else { continue }
                
                if http.statusCode == 401 || http.statusCode == 403 {
                    return RealUsageResult(
                        success: false,
                        message: "La cookie de sesión de Cursor ha expirado o es incorrecta (HTTP \(http.statusCode)). Copia el valor de 'WorkosCursorSessionToken' desde cursor.com",
                        lastSyncStatus: "🔴 Sesión de Cursor expirada"
                    )
                }
                
                guard http.statusCode == 200 else {
                    lastErrorMsg = "Cursor HTTP \(http.statusCode)"
                    continue
                }
                
                struct CursorUsage: Codable {
                    let numRequests: Int?
                    let numRequestsTotal: Int?
                    let maxRequestUsage: Int?
                    let startOfMonth: String?
                }
                
                let decoded = try JSONDecoder().decode(CursorUsage.self, from: data)
                let used = Double(decoded.numRequests ?? 0)
                let limit = Double(decoded.maxRequestUsage ?? 500)
                let usedPct = limit > 0 ? min(100.0, max(0.0, (used / limit) * 100.0)) : 0.0
                
                var resetDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                if let startStr = decoded.startOfMonth {
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let startDate = isoFormatter.date(from: startStr) ?? ISO8601DateFormatter().date(from: startStr) {
                        resetDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? resetDate
                    }
                }
                
                let usedInt = Int(used)
                let limitInt = Int(limit)
                let totalInt = decoded.numRequestsTotal ?? usedInt
                
                return RealUsageResult(
                    success: true,
                    message: "Cursor sincronizado: \(usedInt) de \(limitInt) fast requests usados",
                    lastSyncStatus: "🟢 Conectado (\(usedInt)/\(limitInt) reqs)",
                    hasLiveMetrics: true,
                    primaryLabel: "Fast Requests",
                    primaryUsedPercent: usedPct,
                    primaryResetDate: resetDate,
                    currentCount: used,
                    maxCount: limit,
                    unitName: "reqs",
                    tokensToday: "Fast requests: \(usedInt) / \(limitInt)",
                    tokensMonth: "Peticiones totales en ciclo: \(totalInt)"
                )
            } catch {
                lastErrorMsg = error.localizedDescription
            }
        }
        
        return RealUsageResult(
            success: false,
            message: "Fallo de conexión con Cursor: \(lastErrorMsg). Revisa tu conexión de red o cookie de sesión.",
            lastSyncStatus: "🔴 Error Cursor"
        )
    }
    
    // MARK: - 5. LiteLLM (/key/info)
    private func fetchLiteLLM(token: String, customEndpoint: String) async -> RealUsageResult {
        let base = customEndpoint.isEmpty ? "http://localhost:4000" : customEndpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/key/info") else {
            return RealUsageResult(success: false, message: "URL de LiteLLM inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta", lastSyncStatus: "🔴 Sin respuesta")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "Virtual Key de LiteLLM no autorizada", lastSyncStatus: "🔴 Key no válida")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "LiteLLM respondió HTTP \(http.statusCode)", lastSyncStatus: "🔴 HTTP \(http.statusCode)")
            }
            
            struct LiteLLMKeyInfo: Codable {
                let spend: Double?
                let max_budget: Double?
                let expires: String?
            }
            
            let info = try JSONDecoder().decode(LiteLLMKeyInfo.self, from: data)
            let spend = info.spend ?? 0.0
            let budget = info.max_budget ?? 0.0
            let usedPct = budget > 0 ? min(100.0, (spend / budget) * 100.0) : 0.0
            
            return RealUsageResult(
                success: true,
                message: "LiteLLM sincronizado: $\(String(format: "%.2f", spend)) de $\(String(format: "%.2f", budget))",
                lastSyncStatus: "🟢 $\(String(format: "%.2f", spend))/$\(String(format: "%.2f", budget))",
                hasLiveMetrics: true,
                primaryLabel: "Presupuesto LiteLLM",
                primaryUsedPercent: usedPct,
                currentCount: spend,
                maxCount: budget > 0 ? budget : 100.0,
                unitName: "$",
                tokensToday: "Gasto: $\(String(format: "%.2f", spend))",
                tokensMonth: "Límite: $\(String(format: "%.2f", budget))"
            )
        } catch {
            return RealUsageResult(success: false, message: "No se pudo conectar a LiteLLM en \(base)", lastSyncStatus: "🔴 No responde")
        }
    }
    
    // MARK: - 6. Antigravity (Local Language Server Probe / Google AI Studio)
    private func fetchAntigravity(token: String, customEndpoint: String) async -> RealUsageResult {
        // Option 1: Direct Google Generative Language API Key (AIza...)
        if token.hasPrefix("AIza") {
            let urlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(token)"
            guard let url = URL(string: urlString) else {
                return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
            }
            
            do {
                let (data, response) = try await urlSession.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    struct GeminiModelsResponse: Codable {
                        struct Model: Codable { let name: String? }
                        let models: [Model]?
                    }
                    let decoded = try? JSONDecoder().decode(GeminiModelsResponse.self, from: data)
                    let count = decoded?.models?.count ?? 0
                    
                    return RealUsageResult(
                        success: true,
                        message: "Google Gemini AI Studio activo (\(count) modelos disponibles)",
                        lastSyncStatus: "🟢 Gemini Conectado (\(count) modelos)",
                        hasLiveMetrics: true,
                        primaryLabel: "Google Gemini Pro / Flash",
                        primaryUsedPercent: 0.0,
                        tokensToday: "API Key de Desarrollador Activa",
                        tokensMonth: "\(count) modelos Gemini disponibles"
                    )
                } else {
                    return RealUsageResult(success: false, message: "API Key de Google rechazada", lastSyncStatus: "🔴 Key Gemini inválida")
                }
            } catch {
                return RealUsageResult(success: false, message: "Error al validar Gemini: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de red")
            }
        }
        
        // Option 2: Dynamic Local Antigravity Probe (Language Server / agy CLI)
        struct ProbeTarget {
            let port: Int
            let csrfToken: String?
        }
        
        var targets: [ProbeTarget] = []
        
        // Check custom endpoint if specified by user
        if !customEndpoint.isEmpty, let customURL = URL(string: customEndpoint), let p = customURL.port {
            targets.append(ProbeTarget(port: p, csrfToken: token.isEmpty ? nil : token))
        }
        
        // Discover active Antigravity processes using Darwin kernel & socket inspection
        let discoveredProcesses = DarwinProcessEnumerator.findAntigravityProcesses()
        for proc in discoveredProcesses {
            let csrf = proc.csrfToken ?? proc.extensionServerCsrfToken ?? (token.isEmpty ? nil : token)
            for port in proc.listeningPorts {
                if !targets.contains(where: { $0.port == port }) {
                    targets.append(ProbeTarget(port: port, csrfToken: csrf))
                }
            }
            if let extPort = proc.extensionServerPort, !targets.contains(where: { $0.port == extPort }) {
                targets.append(ProbeTarget(port: extPort, csrfToken: csrf))
            }
        }
        
        // Standard candidate port fallbacks
        let fallbackPorts = [63079, 63080, 50051, 49152, 50000, 51000, 52000, 53000, 54000, 55000, 56000, 57000, 58000, 59000, 60000]
        for port in fallbackPorts {
            if !targets.contains(where: { $0.port == port }) {
                targets.append(ProbeTarget(port: port, csrfToken: token.isEmpty ? nil : token))
            }
        }
        
        // Response model structures for RetrieveUserQuotaSummary
        struct AntigravityQuotaSummaryResponse: Codable {
            struct Bucket: Codable {
                let bucketId: String?
                let displayName: String?
                let description: String?
                let remainingFraction: Double?
                let remaining: Remaining?
                let resetTime: String?
                let disabled: Bool?
                
                struct Remaining: Codable {
                    let remainingFraction: Double?
                }
                
                var fraction: Double? {
                    remainingFraction ?? remaining?.remainingFraction
                }
            }
            
            struct Group: Codable {
                let displayName: String?
                let description: String?
                let buckets: [Bucket]?
            }
            
            struct Payload: Codable {
                let description: String?
                let groups: [Group]?
            }
            
            let response: Payload?
            let summary: Payload?
            let groups: [Group]?
            
            var resolvedGroups: [Group] {
                response?.groups ?? summary?.groups ?? groups ?? []
            }
        }
        
        // Response model for GetUserStatus fallback
        struct AntigravityUserStatusResponse: Codable {
            struct UserStatus: Codable {
                let email: String?
                struct PlanStatus: Codable {
                    struct PlanInfo: Codable {
                        let planDisplayName: String?
                        let displayName: String?
                        let productName: String?
                        let planName: String?
                        var preferredName: String? {
                            planDisplayName ?? displayName ?? productName ?? planName
                        }
                    }
                    let planInfo: PlanInfo?
                }
                let planStatus: PlanStatus?
                struct UserTier: Codable {
                    let name: String?
                }
                let userTier: UserTier?
                struct ModelConfigData: Codable {
                    struct ModelConfig: Codable {
                        let label: String?
                        struct QuotaInfo: Codable {
                            let remainingFraction: Double?
                            let resetTime: String?
                        }
                        let quotaInfo: QuotaInfo?
                    }
                    let clientModelConfigs: [ModelConfig]?
                }
                let cascadeModelConfigData: ModelConfigData?
            }
            let userStatus: UserStatus?
        }
        
        // Probe discovered targets (trying HTTPS first due to local self-signed TLS server, then HTTP)
        for target in targets {
            let schemes = ["https", "http"]
            for scheme in schemes {
                // 1. Try RetrieveUserQuotaSummary (Primary Antigravity 2.0 Quota Grouping)
                if let quotaSummaryURL = URL(string: "\(scheme)://127.0.0.1:\(target.port)/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary") {
                    var req = URLRequest(url: quotaSummaryURL)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
                    if let csrf = target.csrfToken, !csrf.isEmpty {
                        req.setValue(csrf, forHTTPHeaderField: "X-Codeium-Csrf-Token")
                    }
                    req.httpBody = "{}".data(using: .utf8)
                    req.timeoutInterval = 1.5
                    
                    if let (data, response) = try? await urlSession.data(for: req),
                       let http = response as? HTTPURLResponse, http.statusCode == 200,
                       let summary = try? JSONDecoder().decode(AntigravityQuotaSummaryResponse.self, from: data) {
                        
                        var geminiBucket: AntigravityQuotaSummaryResponse.Bucket?
                        var claudeBucket: AntigravityQuotaSummaryResponse.Bucket?
                        
                        for group in summary.resolvedGroups {
                            let groupName = (group.displayName ?? "").lowercased()
                            if groupName.contains("gemini") {
                                geminiBucket = group.buckets?.first(where: { !($0.disabled ?? false) && $0.fraction != nil })
                            } else if groupName.contains("claude") || groupName.contains("gpt") {
                                claudeBucket = group.buckets?.first(where: { !($0.disabled ?? false) && $0.fraction != nil })
                            }
                        }
                        
                        if geminiBucket != nil || claudeBucket != nil {
                            let geminiFraction = geminiBucket?.fraction ?? 1.0
                            let geminiUsedPct = max(0.0, min(100.0, (1.0 - geminiFraction) * 100.0))
                            
                            let claudeFraction = claudeBucket?.fraction ?? 1.0
                            let claudeUsedPct = max(0.0, min(100.0, (1.0 - claudeFraction) * 100.0))
                            
                            var geminiResetDate: Date? = nil
                            if let resetStr = geminiBucket?.resetTime {
                                geminiResetDate = ISO8601DateFormatter().date(from: resetStr)
                            }
                            
                            var claudeResetDate: Date? = nil
                            if let resetStr = claudeBucket?.resetTime {
                                claudeResetDate = ISO8601DateFormatter().date(from: resetStr)
                            }
                            
                            let geminiTitle = geminiBucket?.displayName ?? "Gemini Models"
                            let claudeTitle = claudeBucket?.displayName ?? "Claude/GPT Models"
                            
                            return RealUsageResult(
                                success: true,
                                message: "Antigravity sincronizado (Puerto \(target.port)): Gemini \(String(format: "%.1f", geminiUsedPct))%, Claude/GPT \(String(format: "%.1f", claudeUsedPct))%",
                                lastSyncStatus: "🟢 Gemini: \(Int(geminiUsedPct))% · Claude: \(Int(claudeUsedPct))%",
                                hasLiveMetrics: true,
                                primaryLabel: "Gemini (\(geminiTitle))",
                                primaryUsedPercent: geminiUsedPct,
                                primaryResetDate: geminiResetDate,
                                primaryResetIntervalMinutes: 300,
                                secondaryLabel: "Claude/GPT (\(claudeTitle))",
                                secondaryUsedPercent: claudeUsedPct,
                                secondaryResetDate: claudeResetDate,
                                currentCount: geminiUsedPct,
                                maxCount: 100.0,
                                unitName: "%",
                                tokensToday: "Gemini: \(String(format: "%.1f", geminiUsedPct))% usado",
                                tokensMonth: "Claude/GPT: \(String(format: "%.1f", claudeUsedPct))% usado"
                            )
                        }
                    }
                }
                
                // 2. Try GetUserStatus (Fallback 1)
                if let statusURL = URL(string: "\(scheme)://127.0.0.1:\(target.port)/exa.language_server_pb.LanguageServerService/GetUserStatus") {
                    var req = URLRequest(url: statusURL)
                    req.httpMethod = "POST"
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
                    if let csrf = target.csrfToken, !csrf.isEmpty {
                        req.setValue(csrf, forHTTPHeaderField: "X-Codeium-Csrf-Token")
                    }
                    req.httpBody = "{}".data(using: .utf8)
                    req.timeoutInterval = 1.5
                    
                    if let (data, response) = try? await urlSession.data(for: req),
                       let http = response as? HTTPURLResponse, http.statusCode == 200,
                       let userStatusRes = try? JSONDecoder().decode(AntigravityUserStatusResponse.self, from: data) {
                        
                        let planName = userStatusRes.userStatus?.planStatus?.planInfo?.preferredName ?? userStatusRes.userStatus?.userTier?.name ?? "Google AI"
                        let configs = userStatusRes.userStatus?.cascadeModelConfigData?.clientModelConfigs ?? []
                        
                        let geminiConfig = configs.first(where: { ($0.label ?? "").lowercased().contains("gemini") })
                        let claudeConfig = configs.first(where: { ($0.label ?? "").lowercased().contains("claude") || ($0.label ?? "").lowercased().contains("gpt") })
                        
                        let geminiUsedPct = geminiConfig?.quotaInfo?.remainingFraction.map { max(0.0, min(100.0, (1.0 - $0) * 100.0)) } ?? 0.0
                        let claudeUsedPct = claudeConfig?.quotaInfo?.remainingFraction.map { max(0.0, min(100.0, (1.0 - $0) * 100.0)) } ?? 0.0
                        
                        var geminiResetDate: Date? = nil
                        if let resetStr = geminiConfig?.quotaInfo?.resetTime {
                            geminiResetDate = ISO8601DateFormatter().date(from: resetStr)
                        }
                        
                        return RealUsageResult(
                            success: true,
                            message: "Antigravity conectado (\(planName) en puerto \(target.port))",
                            lastSyncStatus: "🟢 \(planName) (Puerto \(target.port))",
                            hasLiveMetrics: true,
                            primaryLabel: geminiConfig?.label ?? "Gemini Pro/Flash",
                            primaryUsedPercent: geminiUsedPct,
                            primaryResetDate: geminiResetDate,
                            secondaryLabel: claudeConfig?.label ?? "Claude Models",
                            secondaryUsedPercent: claudeUsedPct,
                            currentCount: geminiUsedPct,
                            maxCount: 100.0,
                            unitName: "%",
                            tokensToday: "Gemini: \(String(format: "%.1f", geminiUsedPct))% usado",
                            tokensMonth: "Plan: \(planName)"
                        )
                    }
                }
            }
        }
        
        // Check if Antigravity files exist locally
        let home = FileManager.default.homeDirectoryForCurrentUser
        let hasAntigravityLocal = FileManager.default.fileExists(atPath: home.appendingPathComponent(".gemini/antigravity").path) ||
            FileManager.default.fileExists(atPath: home.appendingPathComponent(".gemini/antigravity-cli").path)
        
        if hasAntigravityLocal {
            return RealUsageResult(
                success: false,
                message: "Antigravity está instalado en tu Mac pero su servidor local está en reposo. Inicia Antigravity.app o ejecuta 'agy' en la terminal para activar el monitoreo en vivo.",
                lastSyncStatus: "🟡 Antigravity en espera",
                hasLiveMetrics: false,
                primaryLabel: "Gemini Models",
                tokensToday: "Inicia Antigravity.app o 'agy'",
                tokensMonth: "O ingresa tu Google Gemini API Key"
            )
        }
        
        // If neither responded:
        return RealUsageResult(
            success: false,
            message: "Antigravity no detectado en ejecución. Inicia Antigravity.app o ingresa una API Key de Google (AIza...)",
            lastSyncStatus: "🟡 Antigravity no activo",
            hasLiveMetrics: false,
            primaryLabel: "Gemini Models",
            tokensToday: "Inicia la app de Antigravity",
            tokensMonth: "O ingresa tu Google Gemini API Key"
        )
    }
    
    // MARK: - 7. Ollama (Local HTTP Probe)
    private func fetchOllama(customEndpoint: String) async -> RealUsageResult {
        let base = customEndpoint.isEmpty ? "http://localhost:11434" : customEndpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/api/tags") else {
            return RealUsageResult(success: false, message: "URL de Ollama inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "Ollama no respondió en \(base)", lastSyncStatus: "⚪ Ollama inactivo")
            }
            
            struct OllamaModel: Codable {
                let name: String?
                let size: Int64?
            }
            struct OllamaTagsResponse: Codable {
                let models: [OllamaModel]?
            }
            
            let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            let models = decoded.models ?? []
            let count = models.count
            let modelNames = models.prefix(3).compactMap { $0.name }.joined(separator: ", ")
            
            return RealUsageResult(
                success: true,
                message: "Ollama detectado en \(base) con \(count) modelos locales",
                lastSyncStatus: "🟢 Ollama Activo (\(count) modelos)",
                hasLiveMetrics: true,
                primaryLabel: "Modelos Locales",
                primaryUsedPercent: 0.0,
                currentCount: Double(count),
                maxCount: Double(max(count, 10)),
                unitName: "modelos",
                tokensToday: "Instalados: \(count) modelos",
                tokensMonth: count > 0 ? "Modelos: \(modelNames)" : "Sin modelos descargados"
            )
        } catch {
            return RealUsageResult(
                success: false,
                message: "Ollama no está corriendo en \(base). Inicia la app de Ollama para usar modelos locales.",
                lastSyncStatus: "⚪ Ollama no responde"
            )
        }
    }
    
    // MARK: - 8. OpenAI / Codex (Local Sessions + API Key / Admin Spend)
    private func fetchOpenAICodex(token: String) async -> RealUsageResult {
        // Step 1: Check local Codex CLI session logs (~/.codex/sessions)
        let localStats = LocalTokenScanner.shared.scanCodexSessions()
        
        // Step 2: If organization admin key (sk-admin-...):
        if token.hasPrefix("sk-admin-") {
            let now = Date()
            let cal = Calendar.current
            let thirtyDaysAgo = cal.date(byAdding: .day, value: -30, to: now) ?? now
            let startMonthUnix = Int(thirtyDaysAgo.timeIntervalSince1970)
            
            let urlString = "https://api.openai.com/v1/organization/costs?start_time=\(startMonthUnix)&limit=30"
            if let url = URL(string: urlString) {
                var req = URLRequest(url: url)
                req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                if let (data, response) = try? await urlSession.data(for: req),
                   let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    struct CostItem: Codable {
                        struct Amount: Codable { let value: Double?; let currency: String? }
                        let amount: Amount?
                    }
                    struct CostsResponse: Codable {
                        let data: [CostItem]?
                    }
                    
                    if let res = try? JSONDecoder().decode(CostsResponse.self, from: data) {
                        let total30d = res.data?.reduce(0.0) { $0 + ($1.amount?.value ?? 0.0) } ?? 0.0
                        return RealUsageResult(
                            success: true,
                            message: "OpenAI Admin conectado. Gasto 30d: $\(String(format: "%.2f", total30d)) USD",
                            lastSyncStatus: "🟢 Gasto 30d: $\(String(format: "%.2f", total30d))",
                            hasLiveMetrics: true,
                            primaryLabel: "Consumo OpenAI Org",
                            primaryUsedPercent: min(100.0, (total30d / 100.0) * 100.0),
                            currentCount: total30d,
                            maxCount: 100.0,
                            unitName: "$",
                            tokensToday: localStats != nil ? "Hoy: \(localStats!.formattedTodayString)" : "Organización OpenAI activa",
                            tokensMonth: "Gasto 30d: $\(String(format: "%.2f", total30d)) USD"
                        )
                    }
                }
            }
        }
        
        // Step 3: If local session files exist on disk:
        if let stats = localStats {
            let todayStr = "Hoy: \(stats.formattedTodayString)"
            let monthStr = "30 días: \(stats.formattedMonthString)"
            let status = "🟢 Codex Local (\(stats.formatTokenCount(stats.totalTokensToday)) hoy)"
            
            // If user also has a standard API key, check it
            if !token.isEmpty, let url = URL(string: "https://api.openai.com/v1/models") {
                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                _ = try? await urlSession.data(for: request)
            }
            
            return RealUsageResult(
                success: true,
                message: "Sesiones locales de Codex sincronizadas: \(stats.totalTokensToday) tokens hoy",
                lastSyncStatus: status,
                hasLiveMetrics: true,
                primaryLabel: "Codex Token Usage",
                primaryUsedPercent: min(100.0, (Double(stats.totalTokensToday) / 500_000.0) * 100.0),
                currentCount: Double(stats.totalTokensToday),
                maxCount: 500_000,
                unitName: "tok",
                tokensToday: todayStr,
                tokensMonth: monthStr
            )
        }
        
        guard !token.isEmpty else {
            return RealUsageResult(
                success: false,
                message: "No se encontraron sesiones locales en ~/.codex/sessions. Ingresa tu API Key de OpenAI (sk-...)",
                lastSyncStatus: "⚠️ Requiere API Key o Codex CLI"
            )
        }
        
        // Standard Developer Key verification
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta de OpenAI", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "API Key de OpenAI inválida (401 Unauthorized)", lastSyncStatus: "🔴 Key inválida")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "OpenAI respondió con código HTTP \(http.statusCode)", lastSyncStatus: "🔴 Error \(http.statusCode)")
            }
            
            return RealUsageResult(
                success: true,
                message: "OpenAI API Key verificada exitosamente",
                lastSyncStatus: "🟢 Conectado a OpenAI",
                hasLiveMetrics: true,
                primaryLabel: "OpenAI Platform API",
                primaryUsedPercent: 0.0,
                tokensToday: "API Key verificada en tiempo real",
                tokensMonth: "Usa sk-admin-... para ver desglose de gasto en $"
            )
        } catch {
            return RealUsageResult(success: false, message: "Error al conectar con OpenAI: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 9. Anthropic / Claude (Local Claude Code Sessions + API Key)
    private func fetchClaude(token: String) async -> RealUsageResult {
        // Step 1: Check local Claude Code session logs (~/.claude/projects)
        let localStats = LocalTokenScanner.shared.scanClaudeSessions()
        
        if let stats = localStats {
            let todayStr = "Hoy: \(stats.formattedTodayString)"
            let monthStr = "30 días: \(stats.formattedMonthString)"
            let status = "🟢 Claude Code (\(stats.formatTokenCount(stats.totalTokensToday)) hoy)"
            
            // If user also provided an API key, check rate limits
            if !token.isEmpty, let url = URL(string: "https://api.anthropic.com/v1/models") {
                var req = URLRequest(url: url)
                req.setValue(token, forHTTPHeaderField: "x-api-key")
                req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                _ = try? await urlSession.data(for: req)
            }
            
            return RealUsageResult(
                success: true,
                message: "Sesiones locales de Claude Code sincronizadas: \(stats.totalTokensToday) tokens hoy",
                lastSyncStatus: status,
                hasLiveMetrics: true,
                primaryLabel: "Claude Code CLI Tokens",
                primaryUsedPercent: min(100.0, (Double(stats.totalTokensToday) / 500_000.0) * 100.0),
                currentCount: Double(stats.totalTokensToday),
                maxCount: 500_000,
                unitName: "tok",
                tokensToday: todayStr,
                tokensMonth: monthStr
            )
        }
        
        guard !token.isEmpty else {
            return RealUsageResult(
                success: false,
                message: "No se detectaron sesiones de Claude Code en ~/.claude/projects. Ingresa tu API Key de Anthropic (sk-ant-...)",
                lastSyncStatus: "⚠️ Requiere API Key o Claude Code"
            )
        }
        
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta de Anthropic", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "API Key de Anthropic inválida (401)", lastSyncStatus: "🔴 Key inválida")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "Anthropic HTTP \(http.statusCode)", lastSyncStatus: "🔴 Error \(http.statusCode)")
            }
            
            let remReqHeader = http.value(forHTTPHeaderField: "anthropic-ratelimit-requests-remaining")
            let limReqHeader = http.value(forHTTPHeaderField: "anthropic-ratelimit-requests-limit")
            let remTokHeader = http.value(forHTTPHeaderField: "anthropic-ratelimit-tokens-remaining")
            
            var rateDesc = "Conectado"
            var usedPct = 0.0
            if let rem = Double(remReqHeader ?? ""), let lim = Double(limReqHeader ?? ""), lim > 0 {
                let used = lim - rem
                usedPct = min(100.0, max(0.0, (used / lim) * 100.0))
                rateDesc = "\(Int(rem)) reqs/min restantes"
            }
            
            return RealUsageResult(
                success: true,
                message: "Anthropic Claude verificado en vivo. \(rateDesc).",
                lastSyncStatus: "🟢 Conectado (\(rateDesc))",
                hasLiveMetrics: true,
                primaryLabel: "Rate Limit (Peticiones/min)",
                primaryUsedPercent: usedPct,
                tokensToday: "Tokens/min restantes: \(remTokHeader ?? "Ilimitado")",
                tokensMonth: "Peticiones/min: \(remReqHeader ?? "-") / \(limReqHeader ?? "-")"
            )
        } catch {
            return RealUsageResult(success: false, message: "Error al conectar con Claude: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 10. GitHub Copilot (/copilot_internal/v2/token)
    private func fetchCopilot(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu GitHub Personal Access Token (ghp_... o oauth token)", lastSyncStatus: "⚠️ Requiere Token")
        }
        
        guard let url = URL(string: "https://api.github.com/copilot_internal/v2/token") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("CoderBar-App", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta de GitHub", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode == 401 {
                return RealUsageResult(success: false, message: "Token de GitHub no autorizado o expirado (401)", lastSyncStatus: "🔴 Token inválido")
            }
            
            if http.statusCode == 403 {
                return RealUsageResult(success: false, message: "El usuario no tiene una suscripción activa a GitHub Copilot", lastSyncStatus: "🟠 Sin plan Copilot")
            }
            
            guard http.statusCode == 200 else {
                return RealUsageResult(success: false, message: "GitHub Copilot HTTP \(http.statusCode)", lastSyncStatus: "🔴 Error \(http.statusCode)")
            }
            
            struct CopilotTokenResponse: Codable {
                let sku: String?
                let expires_at: Int?
            }
            
            let decoded = try? JSONDecoder().decode(CopilotTokenResponse.self, from: data)
            let skuName = decoded?.sku ?? "Copilot Activo"
            let expiryDate = decoded?.expires_at != nil ? Date(timeIntervalSince1970: TimeInterval(decoded!.expires_at!)) : Date().addingTimeInterval(3600 * 24)
            
            return RealUsageResult(
                success: true,
                message: "GitHub Copilot conectado exitosamente (Plan: \(skuName))",
                lastSyncStatus: "🟢 Activo (\(skuName))",
                hasLiveMetrics: true,
                primaryLabel: "GitHub Copilot Plan",
                primaryUsedPercent: 0.0,
                primaryResetDate: expiryDate,
                tokensToday: "Plan detectado: \(skuName)",
                tokensMonth: "Token interno renovado en vivo"
            )
        } catch {
            return RealUsageResult(success: false, message: "Error al conectar con GitHub: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 11. Zed Editor AI
    private func fetchZed(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu token de Zed", lastSyncStatus: "⚠️ Requiere Token")
        }
        
        guard let url = URL(string: "https://cloud.zed.dev/client/users/me") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return RealUsageResult(
                    success: true,
                    message: "Cuenta de Zed Editor verificada con éxito",
                    lastSyncStatus: "🟢 Zed Conectado",
                    hasLiveMetrics: true,
                    primaryLabel: "Zed AI Plan",
                    tokensToday: "Cuenta sincronizada",
                    tokensMonth: "cloud.zed.dev conectado"
                )
            } else {
                return RealUsageResult(success: false, message: "Token de Zed rechazado", lastSyncStatus: "🔴 Token inválido")
            }
        } catch {
            return RealUsageResult(success: false, message: "Error al conectar con Zed: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 12. Devin (/billing/quota/usage)
    private func fetchDevin(token: String, customEndpoint: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu token de sesión auth1_session de Devin", lastSyncStatus: "⚠️ Requiere Token")
        }
        
        let endpointUrl = customEndpoint.isEmpty ? "https://api.devin.ai/api/v1/sessions" : customEndpoint
        guard let url = URL(string: endpointUrl) else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return RealUsageResult(
                    success: true,
                    message: "Devin conectado en vivo",
                    lastSyncStatus: "🟢 Devin Conectado",
                    hasLiveMetrics: true,
                    primaryLabel: "Devin Session Quota",
                    tokensToday: "Sesión activa verificada",
                    tokensMonth: "Cognition Devin Agent"
                )
            } else {
                return RealUsageResult(success: false, message: "Token de Devin rechazado (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))", lastSyncStatus: "🔴 Error Devin")
            }
        } catch {
            return RealUsageResult(success: false, message: "Error Devin: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de conexión")
        }
    }
    
    // MARK: - 13. Kiro (CLI or Endpoint)
    private func fetchKiro(token: String, customEndpoint: String) async -> RealUsageResult {
        if !customEndpoint.isEmpty, let url = URL(string: customEndpoint) {
            var request = URLRequest(url: url)
            if !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            if let (_, response) = try? await urlSession.data(for: request),
               let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return RealUsageResult(
                    success: true,
                    message: "Endpoint de Kiro respondió OK",
                    lastSyncStatus: "🟢 Conectado",
                    hasLiveMetrics: true
                )
            }
        }
        
        // Check if kiro-cli exists on system
        let fileManager = FileManager.default
        let standardPaths = ["/usr/local/bin/kiro-cli", "/opt/homebrew/bin/kiro-cli"]
        let found = standardPaths.contains { fileManager.fileExists(atPath: $0) }
        
        if found {
            return RealUsageResult(
                success: true,
                message: "Kiro CLI detectado en sistema",
                lastSyncStatus: "🟢 CLI Detectado",
                hasLiveMetrics: true,
                primaryLabel: "Kiro CLI Quota",
                tokensToday: "kiro-cli chat integrado",
                tokensMonth: "CLI disponible en PATH"
            )
        } else {
            return RealUsageResult(
                success: false,
                message: "kiro-cli no encontrado en /opt/homebrew/bin o /usr/local/bin. Instala Kiro CLI o ingresa un endpoint.",
                lastSyncStatus: "🟡 kiro-cli no encontrado"
            )
        }
    }
    
    // MARK: - 14. Perplexity
    private func fetchPerplexity(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu API Key de Perplexity (pplx-...)", lastSyncStatus: "⚠️ Requiere Key")
        }
        
        guard let url = URL(string: "https://api.perplexity.ai/models") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return RealUsageResult(
                    success: true,
                    message: "Perplexity API Key verificada",
                    lastSyncStatus: "🟢 Perplexity Conectado",
                    hasLiveMetrics: true,
                    primaryLabel: "Perplexity Pro API",
                    tokensToday: "API Key activa",
                    tokensMonth: "Acceso a modelos Sonar & Deep Research"
                )
            } else {
                return RealUsageResult(success: false, message: "Key de Perplexity rechazada", lastSyncStatus: "🔴 Key inválida")
            }
        } catch {
            return RealUsageResult(success: false, message: "Error Perplexity: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de red")
        }
    }
    
    // MARK: - 15. Mistral
    private func fetchMistral(token: String) async -> RealUsageResult {
        guard !token.isEmpty else {
            return RealUsageResult(success: false, message: "Ingresa tu API Key de Mistral", lastSyncStatus: "⚠️ Requiere Key")
        }
        
        guard let url = URL(string: "https://api.mistral.ai/v1/models") else {
            return RealUsageResult(success: false, message: "URL inválida", lastSyncStatus: "🔴 Error URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                return RealUsageResult(
                    success: true,
                    message: "Mistral AI conectado exitosamente",
                    lastSyncStatus: "🟢 Mistral Conectado",
                    hasLiveMetrics: true,
                    primaryLabel: "Mistral Platform",
                    tokensToday: "API Key activa",
                    tokensMonth: "Acceso a Mistral Large & Codestral"
                )
            } else {
                return RealUsageResult(success: false, message: "Key de Mistral rechazada", lastSyncStatus: "🔴 Key inválida")
            }
        } catch {
            return RealUsageResult(success: false, message: "Error Mistral: \(error.localizedDescription)", lastSyncStatus: "🔴 Error de red")
        }
    }
    
    // MARK: - 16. Generic Provider Fallback with Dynamic Parsing
    private func fetchGenericProvider(provider: ProviderUsage, token: String, endpoint: String) async -> RealUsageResult {
        guard !token.isEmpty || !endpoint.isEmpty else {
            return RealUsageResult(
                success: false,
                message: "Ingresa tu API Key o Token para \(provider.id.displayName)",
                lastSyncStatus: "⚠️ Requiere Credenciales"
            )
        }
        
        guard !endpoint.isEmpty, let url = URL(string: endpoint) else {
            return RealUsageResult(
                success: true,
                message: "Credencial de \(provider.id.displayName) guardada localmente",
                lastSyncStatus: "🟢 Guardado local",
                hasLiveMetrics: false,
                tokensToday: "Credencial configurada",
                tokensMonth: "Especifica endpoint para métricas en vivo"
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return RealUsageResult(success: false, message: "Sin respuesta", lastSyncStatus: "🔴 Error de red")
            }
            
            if http.statusCode >= 200 && http.statusCode < 300 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var parsedUsage: Double?
                    var parsedLimit: Double?
                    
                    let usageKeys = ["usage", "used", "spend", "current", "requests", "total_usage", "character_count"]
                    let limitKeys = ["limit", "max", "budget", "max_budget", "quota", "character_limit"]
                    
                    for key in usageKeys {
                        if let val = json[key] as? Double { parsedUsage = val; break }
                        if let val = json[key] as? Int { parsedUsage = Double(val); break }
                    }
                    for key in limitKeys {
                        if let val = json[key] as? Double { parsedLimit = val; break }
                        if let val = json[key] as? Int { parsedLimit = Double(val); break }
                    }
                    
                    let pct: Double
                    if let u = parsedUsage, let l = parsedLimit, l > 0 {
                        pct = min(100.0, (u / l) * 100.0)
                    } else {
                        pct = 0.0
                    }
                    
                    return RealUsageResult(
                        success: true,
                        message: "Conexión exitosa con \(provider.id.displayName)",
                        lastSyncStatus: "🟢 Conectado en vivo",
                        hasLiveMetrics: parsedUsage != nil,
                        primaryUsedPercent: pct,
                        currentCount: parsedUsage,
                        maxCount: parsedLimit,
                        tokensToday: parsedUsage != nil ? "Consumo: \(parsedUsage!)" : "Respuesta OK (HTTP 200)",
                        tokensMonth: parsedLimit != nil ? "Límite: \(parsedLimit!)" : "\(provider.id.displayName) API"
                    )
                }
                
                return RealUsageResult(
                    success: true,
                    message: "Conexión exitosa con \(provider.id.displayName) (HTTP 200)",
                    lastSyncStatus: "🟢 Conectado",
                    hasLiveMetrics: true
                )
            } else {
                return RealUsageResult(
                    success: false,
                    message: "\(provider.id.displayName) respondió con HTTP \(http.statusCode)",
                    lastSyncStatus: "🔴 Error HTTP \(http.statusCode)"
                )
            }
        } catch {
            return RealUsageResult(
                success: false,
                message: "No se pudo conectar con \(provider.id.displayName): \(error.localizedDescription)",
                lastSyncStatus: "🔴 Error de conexión"
            )
        }
    }
}
