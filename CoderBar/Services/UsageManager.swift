//
//  UsageManager.swift
//  Usage Notch
//

import SwiftUI
import Combine

public enum NotchPosition: String, CaseIterable, Codable, Identifiable {
    case rightEdge = "Borde Derecho"
    case leftEdge = "Borde Izquierdo"
    case topNotch = "Notch Superior (MacBook)"
    
    public var id: String { rawValue }
}

public enum EdgeAlignment: String, CaseIterable, Codable, Identifiable {
    case top = "Arriba"
    case center = "Centro"
    case bottom = "Abajo"
    
    public var id: String { rawValue }
}

@MainActor
public final class UsageManager: ObservableObject {
    public static let shared = UsageManager()
    
    @Published public var providers: [ProviderUsage] = []
    @Published public var selectedProviderId: AIProviderType? = nil
    
    // Position & Alignment settings
    @Published public var position: NotchPosition = .rightEdge {
        didSet {
            UserDefaults.standard.set(position.rawValue, forKey: "usage_notch_position")
            notifyLayoutChange()
        }
    }
    
    @Published public var edgeAlignment: EdgeAlignment = .top {
        didSet {
            UserDefaults.standard.set(edgeAlignment.rawValue, forKey: "usage_notch_alignment")
            notifyLayoutChange()
        }
    }
    
    @Published public var verticalOffset: Double = 0.0 {
        didSet {
            UserDefaults.standard.set(verticalOffset, forKey: "usage_notch_v_offset")
            notifyLayoutChange()
        }
    }
    
    @Published public var primaryProviderId: AIProviderType = .claude {
        didSet {
            UserDefaults.standard.set(primaryProviderId.rawValue, forKey: "usage_notch_primary_provider")
        }
    }
    
    // Expansion & Visibility
    @Published public var isExpanded: Bool = false {
        didSet {
            notifyExpandStateChanged()
        }
    }
    
    @Published public var isHudVisible: Bool = true {
        didSet {
            UserDefaults.standard.set(isHudVisible, forKey: "usage_notch_visible")
            notifyLayoutChange()
        }
    }
    
    private var timerCancellable: AnyCancellable?
    private let storageKey = "usage_notch_providers_data"
    
    public init() {
        loadSettings()
        startTimer()
    }
    
    public var primaryUsage: ProviderUsage {
        providers.first(where: { $0.id == primaryProviderId && $0.isEnabled })
            ?? providers.first(where: { $0.isEnabled })
            ?? providers[0]
    }
    
    private func loadSettings() {
        if let savedPos = UserDefaults.standard.string(forKey: "usage_notch_position"),
           let pos = NotchPosition(rawValue: savedPos) {
            self.position = pos
        }
        if let savedAlign = UserDefaults.standard.string(forKey: "usage_notch_alignment"),
           let align = EdgeAlignment(rawValue: savedAlign) {
            self.edgeAlignment = align
        }
        self.verticalOffset = UserDefaults.standard.double(forKey: "usage_notch_v_offset")
        if let savedPrimary = UserDefaults.standard.string(forKey: "usage_notch_primary_provider"),
           let primary = AIProviderType(rawValue: savedPrimary) {
            self.primaryProviderId = primary
        }
        if UserDefaults.standard.object(forKey: "usage_notch_visible") != nil {
            self.isHudVisible = UserDefaults.standard.bool(forKey: "usage_notch_visible")
        }
        
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ProviderUsage].self, from: data),
           !decoded.isEmpty {
            self.providers = decoded
        } else {
            self.providers = [
                ProviderUsage(
                    id: .claude,
                    isEnabled: true,
                    primaryLabel: "Current session",
                    primaryUsedPercent: 73.0,
                    primaryResetIntervalMinutes: 51,
                    secondaryLabel: "All models",
                    secondaryUsedPercent: 7.0,
                    currentCount: 73,
                    maxCount: 100,
                    unitName: "%"
                ),
                ProviderUsage(
                    id: .cursor,
                    isEnabled: true,
                    primaryLabel: "Fast requests",
                    primaryUsedPercent: 21.0,
                    primaryResetIntervalMinutes: 1440 * 12,
                    secondaryLabel: "Slow requests",
                    secondaryUsedPercent: 12.0,
                    currentCount: 105,
                    maxCount: 500,
                    unitName: "reqs"
                ),
                ProviderUsage(
                    id: .antigravity,
                    isEnabled: true,
                    primaryLabel: "Agent runs",
                    primaryUsedPercent: 52.0,
                    primaryResetIntervalMinutes: 360,
                    secondaryLabel: "Daily quota",
                    secondaryUsedPercent: 45.0,
                    currentCount: 52,
                    maxCount: 100,
                    unitName: "tasks"
                ),
                ProviderUsage(
                    id: .claudeCode,
                    isEnabled: true,
                    primaryLabel: "CLI session",
                    primaryUsedPercent: 35.0,
                    primaryResetIntervalMinutes: 180,
                    secondaryLabel: "Token budget",
                    secondaryUsedPercent: 28.0,
                    currentCount: 35000,
                    maxCount: 100000,
                    unitName: "tokens"
                ),
                ProviderUsage(
                    id: .kiro,
                    isEnabled: true,
                    primaryLabel: "Daily requests",
                    primaryUsedPercent: 18.0,
                    primaryResetIntervalMinutes: 720,
                    secondaryLabel: "Weekly quota",
                    secondaryUsedPercent: 14.0,
                    currentCount: 18,
                    maxCount: 100,
                    unitName: "reqs"
                )
            ]
            save()
        }
    }
    
    public func save() {
        if let encoded = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    public func notifyLayoutChange() {
        NotificationCenter.default.post(name: .notchLayoutChanged, object: nil)
    }
    
    public func notifyExpandStateChanged() {
        NotificationCenter.default.post(name: .notchExpandStateChanged, object: nil)
    }
    
    public func toggleExpand() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            isExpanded.toggle()
            if !isExpanded {
                selectedProviderId = nil
            }
        }
    }
    
    public func collapse() {
        if isExpanded {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                isExpanded = false
                selectedProviderId = nil
            }
        }
    }
    
    public func updateUsage(for id: AIProviderType, primaryPercent: Double) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            providers[index].primaryUsedPercent = min(100.0, max(0.0, primaryPercent))
            save()
        }
    }
    
    public func adjustUsage(for id: AIProviderType, delta: Double) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            let newVal = min(100.0, max(0.0, providers[index].primaryUsedPercent + delta))
            providers[index].primaryUsedPercent = newVal
            save()
        }
    }
    
    public func resetSession(for id: AIProviderType) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            providers[index].primaryUsedPercent = 0.0
            providers[index].primaryResetDate = Date().addingTimeInterval(TimeInterval(providers[index].primaryResetIntervalMinutes * 60))
            save()
        }
    }
    
    public func toggleProvider(_ id: AIProviderType) {
        if let index = providers.firstIndex(where: { $0.id == id }) {
            providers[index].isEnabled.toggle()
            save()
        }
    }
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
}

public extension Notification.Name {
    static let notchLayoutChanged = Notification.Name("usage_notch_layout_changed")
    static let notchExpandStateChanged = Notification.Name("usage_notch_expand_state_changed")
    static let notchPositionChanged = Notification.Name("usage_notch_position_changed")
    static let notchVisibilityChanged = Notification.Name("usage_notch_visibility_changed")
}
