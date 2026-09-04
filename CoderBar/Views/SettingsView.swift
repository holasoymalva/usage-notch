//
//  SettingsView.swift
//  Usage Notch
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject var usageManager = UsageManager.shared
    @ObservedObject var apiService = APIUsageService.shared
    
    @State private var selectedProviderId: AIProviderType = .cursor
    @State private var testResultMessages: [AIProviderType: (success: Bool, message: String)] = [:]
    
    public init() {}
    
    public var body: some View {
        TabView {
            servicesConfigTab
                .tabItem {
                    Label("Servicios IA", systemImage: "cpu.fill")
                }
            
            positionTab
                .tabItem {
                    Label("Posición", systemImage: "macwindow.on.rectangle")
                }
            
            aboutTab
                .tabItem {
                    Label("Acerca de", systemImage: "info.circle")
                }
        }
        .frame(width: 580, height: 500)
        .padding()
    }
    
    // MARK: - Tab Servicios IA (Configurar y Conectar)
    private var servicesConfigTab: some View {
        HSplitView {
            // Left sidebar: Provider selector list
            List(usageManager.providers, id: \.id, selection: $selectedProviderId) { item in
                HStack(spacing: 8) {
                    ProviderBrandIcon(provider: item.id, size: 16, color: item.id.defaultAccentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.id.displayName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(item.connectionMode == .api ? "API en vivo" : "Manual")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if item.isEnabled {
                        Circle()
                            .fill(item.lastSyncStatus.contains("🟢") ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                    }
                }
                .tag(item.id)
                .padding(.vertical, 2)
            }
            .frame(minWidth: 160, maxWidth: 180)
            
            // Right detail area: Configuration form for selected provider
            if let index = usageManager.providers.firstIndex(where: { $0.id == selectedProviderId }) {
                providerDetailForm(index: index)
                    .frame(minWidth: 360)
            }
        }
    }
    
    @ViewBuilder
    private func providerDetailForm(index: Int) -> some View {
        let provider = usageManager.providers[index]
        
        Form {
            Section {
                HStack {
                    ProviderBrandIcon(provider: provider.id, size: 24, color: provider.id.defaultAccentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.id.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(provider.id.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Activo en Notch", isOn: $usageManager.providers[index].isEnabled)
                        .onChange(of: usageManager.providers[index].isEnabled) { _ in
                            usageManager.save()
                        }
                }
            }
            
            Section("Modo de Conexión") {
                Picker("Método de monitoreo:", selection: $usageManager.providers[index].connectionMode) {
                    ForEach(ConnectionMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: usageManager.providers[index].connectionMode) { _ in
                    usageManager.save()
                }
            }
            
            if provider.connectionMode == .api {
                apiConfigurationSection(index: index)
            } else {
                manualConfigurationSection(index: index)
            }
            
            Section("Métricas y Umbrales") {
                HStack {
                    Text("Consumo reportado:")
                    Spacer()
                    Text("\(Int(provider.primaryUsedPercent))% (\(Int(provider.currentCount))/\(Int(provider.maxCount)) \(provider.unitName))")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(provider.id.defaultAccentColor)
                }
                
                HStack {
                    Text("Estado de sincronización:")
                    Spacer()
                    Text(provider.lastSyncStatus)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    @ViewBuilder
    private func apiConfigurationSection(index: Int) -> some View {
        let provider = usageManager.providers[index]
        
        Section("Credenciales de la API") {
            VStack(alignment: .leading, spacing: 6) {
                switch provider.id {
                case .cursor:
                    Text("Cookie de Sesión Cursor (WorkosCursorSessionToken):")
                        .font(.caption)
                        .fontWeight(.semibold)
                    SecureField("WorkosCursorSessionToken...", text: $usageManager.providers[index].apiKeyOrToken)
                        .textFieldStyle(.roundedBorder)
                    Text("Tip: Inicia sesión en cursor.com > Abre DevTools (F12) > Application > Cookies > copia el valor de 'WorkosCursorSessionToken'.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                case .claude:
                    Text("Anthropic API Key:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    SecureField("sk-ant-...", text: $usageManager.providers[index].apiKeyOrToken)
                        .textFieldStyle(.roundedBorder)
                    Text("Monitorea los rate limits oficiales de requests y tokens por minuto de tu cuenta de Anthropic.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                case .antigravity:
                    Text("Gemini API Key o OpenRouter Key:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    SecureField("sk-or-... o AIza...", text: $usageManager.providers[index].apiKeyOrToken)
                        .textFieldStyle(.roundedBorder)
                    Text("Permite consultar el balance y cuota activa en vivo.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                case .claudeCode:
                    Text("Anthropic API Key (CLI):")
                        .font(.caption)
                        .fontWeight(.semibold)
                    SecureField("sk-ant-...", text: $usageManager.providers[index].apiKeyOrToken)
                        .textFieldStyle(.roundedBorder)
                    
                case .kiro:
                    Text("Token de API o Bearer:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    SecureField("Bearer token...", text: $usageManager.providers[index].apiKeyOrToken)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Endpoint personalizado (opcional):")
                        .font(.caption)
                        .padding(.top, 4)
                    TextField("https://api.tu-servicio.com/usage", text: $usageManager.providers[index].customEndpoint)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .onChange(of: usageManager.providers[index].apiKeyOrToken) { _ in
                usageManager.save()
            }
            .onChange(of: usageManager.providers[index].customEndpoint) { _ in
                usageManager.save()
            }
            
            HStack {
                Button(action: {
                    Task {
                        let res = await apiService.testAndSync(providerId: provider.id)
                        testResultMessages[provider.id] = res
                    }
                }) {
                    HStack(spacing: 6) {
                        if apiService.testingProviderId == provider.id {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "bolt.horizontal.fill")
                        }
                        Text("Probar Conexión y Guardar")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(apiService.testingProviderId == provider.id)
                
                Spacer()
            }
            .padding(.top, 4)
            
            if let result = testResultMessages[provider.id] {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.message)
                        .font(.caption2)
                        .foregroundColor(result.success ? .green : .red)
                }
                .padding(.top, 2)
            }
        }
    }
    
    @ViewBuilder
    private func manualConfigurationSection(index: Int) -> some View {
        Section("Configuración de Cuota Fija (Plan Pro)") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Porcentaje de uso actual:")
                    Spacer()
                    Text("\(Int(usageManager.providers[index].primaryUsedPercent))%")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                }
                
                Slider(value: $usageManager.providers[index].primaryUsedPercent, in: 0...100, step: 1)
                    .tint(.orange)
                    .onChange(of: usageManager.providers[index].primaryUsedPercent) { _ in
                        usageManager.save()
                    }
                
                HStack {
                    Text("Ventana de reinicio:")
                    Spacer()
                    Picker("", selection: $usageManager.providers[index].primaryResetIntervalMinutes) {
                        Text("5 horas (Claude Pro)").tag(300)
                        Text("24 horas (Diario)").tag(1440)
                        Text("Semanal").tag(10080)
                        Text("Mensual (Cursor)").tag(43200)
                    }
                    .labelsHidden()
                    .onChange(of: usageManager.providers[index].primaryResetIntervalMinutes) { _ in
                        usageManager.save()
                    }
                }
                
                Button("Reiniciar contador a 0% ahora") {
                    usageManager.resetSession(for: usageManager.providers[index].id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    // MARK: - Tab Posición
    private var positionTab: some View {
        Form {
            Section("Ubicación en Pantalla") {
                Picker("Borde de anclaje:", selection: $usageManager.position) {
                    ForEach(NotchPosition.allCases) { pos in
                        Text(pos.rawValue).tag(pos)
                    }
                }
                .pickerStyle(.segmented)
                
                if usageManager.position != .topNotch {
                    Picker("Alineación vertical:", selection: $usageManager.edgeAlignment) {
                        ForEach(EdgeAlignment.allCases) { align in
                            Text(align.rawValue).tag(align)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Ajuste fino de altura:")
                            Spacer()
                            Text("\(Int(usageManager.verticalOffset)) px")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $usageManager.verticalOffset, in: -250...250, step: 5)
                            .tint(.orange)
                        
                        HStack {
                            Text("Más abajo")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Restablecer a 0") {
                                usageManager.verticalOffset = 0
                            }
                            .buttonStyle(.plain)
                            .font(.caption2)
                            .foregroundColor(.orange)
                            Spacer()
                            Text("Más arriba")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Section("Icono en Modo Reposo ('Bolita')") {
                Picker("Herramienta visible en la bolita:", selection: $usageManager.primaryProviderId) {
                    ForEach(usageManager.providers.filter { $0.isEnabled }) { item in
                        HStack {
                            ProviderBrandIcon(provider: item.id, size: 14, color: item.id.defaultAccentColor)
                            Text(item.id.displayName)
                        }
                        .tag(item.id)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Tab Acerca de
    private var aboutTab: some View {
        VStack(spacing: 14) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.5
                            )
                    )
                    .shadow(color: Color.orange.opacity(0.3), radius: 8)
                
                ClaudeStarburstIcon(size: 28, color: .white)
            }
            
            VStack(spacing: 4) {
                Text("Usage Notch")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Versión 1.2.0 (macOS Native)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Text("Conexión directa con APIs de Cursor, Anthropic, Gemini y OpenRouter para monitoreo en vivo de cuotas y consumo de desarrolladores.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
            
            Divider().frame(width: 180)
            
            Text("100% Local • Sandboxed • macOS App Store Compliant")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
