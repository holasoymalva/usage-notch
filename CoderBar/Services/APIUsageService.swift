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
        
        defer {
            testingProviderId = nil
        }
        
        let result = await RealUsageFetchEngine.shared.fetchUsage(for: provider)
        
        // Update provider with real data
        UsageManager.shared.providers[index].lastSyncStatus = result.lastSyncStatus
        UsageManager.shared.providers[index].hasLiveMetrics = result.hasLiveMetrics
        UsageManager.shared.providers[index].lastSyncDate = Date()
        
        if let label = result.primaryLabel {
            UsageManager.shared.providers[index].primaryLabel = label
        }
        if let pct = result.primaryUsedPercent {
            UsageManager.shared.providers[index].primaryUsedPercent = pct
        }
        if let resetDate = result.primaryResetDate {
            UsageManager.shared.providers[index].primaryResetDate = resetDate
        }
        if let interval = result.primaryResetIntervalMinutes {
            UsageManager.shared.providers[index].primaryResetIntervalMinutes = interval
        }
        if let secLabel = result.secondaryLabel {
            UsageManager.shared.providers[index].secondaryLabel = secLabel
        }
        if let secPct = result.secondaryUsedPercent {
            UsageManager.shared.providers[index].secondaryUsedPercent = secPct
        }
        if let secResetDate = result.secondaryResetDate {
            UsageManager.shared.providers[index].secondaryResetDate = secResetDate
        }
        if let curCount = result.currentCount {
            UsageManager.shared.providers[index].currentCount = curCount
        }
        if let maxCount = result.maxCount {
            UsageManager.shared.providers[index].maxCount = maxCount
        }
        if let unit = result.unitName {
            UsageManager.shared.providers[index].unitName = unit
        }
        if let tToday = result.tokensToday {
            UsageManager.shared.providers[index].tokensToday = tToday
        }
        if let tMonth = result.tokensMonth {
            UsageManager.shared.providers[index].tokensMonth = tMonth
        }
        
        UsageManager.shared.save()
        UsageManager.shared.notifyLayoutChange()
        
        return (result.success, result.message)
    }
}
