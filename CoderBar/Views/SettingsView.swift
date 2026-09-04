//
//  SettingsView.swift
//  Usage Notch
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject var usageManager = UsageManager.shared
    @ObservedObject var apiService = APIUsageService.shared
    
    @State private var selectedCategory: ProviderCategory = .all
    @State private var searchText: String = ""
    @State private var editingProviderId: AIProviderType? = nil
    @State private var testResultMessages: [AIProviderType: (success: Bool, message: String)] = [:]
    
    public init() {}
    
    private var filteredProviders: [ProviderUsage] {
        usageManager.providers.filter { item in
            let matchesCategory: Bool
            switch selectedCategory {
            case .all:
                matchesCategory = true
            case .active:
                matchesCategory = item.isEnabled
            default:
                matchesCategory = item.id.category == selectedCategory
            }
            
            if !matchesCategory { return false }
            
            let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            if query.isEmpty { return true }
            
            return item.id.displayName.lowercased().contains(query) ||
                   item.id.authMethod.rawValue.lowercased().contains(query) ||
                   item.id.subtitle.lowercased().contains(query)
        }
    }
    
    private var activeCount: Int {
        usageManager.providers.filter { $0.isEnabled }.count
    }
    
    public var body: some View {
        TabView {
            providersCatalogTab
                .tabItem {
                    Label("Proveedores", systemImage: "square.grid.3x3.fill")
                }
            
            directionPositionTab
                .tabItem {
                    Label("Dirección y Posición", systemImage: "arrow.left.and.right.square.fill")
                }
            
            aboutTab
                .tabItem {
                    Label("Acerca de", systemImage: "info.circle.fill")
                }
        }
        .frame(width: 820, height: 600)
        .sheet(item: $editingProviderId) { providerId in
            if let index = usageManager.providers.firstIndex(where: { $0.id == providerId }) {
                ProviderConfigSheet(
                    index: index,
                    usageManager: usageManager,
                    apiService: apiService,
                    testResult: testResultMessages[providerId],
                    onTest: {
                        Task {
                            let res = await apiService.testAndSync(providerId: providerId)
                            testResultMessages[providerId] = res
                        }
                    },
                    onDismiss: {
                        editingProviderId = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Tab 1: Catálogo de Proveedores de Herramientas
    private var providersCatalogTab: some View {
        VStack(spacing: 14) {
            // Header: Search & Category Filter Pills
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Buscar proveedor (ej. DeepSeek, Codex, Cursor, Claude...)", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.05, green: 0.90, blue: 0.48))
                            .frame(width: 8, height: 8)
                        Text("\(activeCount) activos en Notch")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.12)))
                }
                
                // Category Pills
                HStack(spacing: 8) {
                    ForEach(ProviderCategory.allCases) { cat in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCategory = cat
                            }
                        }) {
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: selectedCategory == cat ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == cat ? Color.white.opacity(0.20) : Color(white: 0.12))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == cat ? Color.white.opacity(0.35) : Color.white.opacity(0.05), lineWidth: 1)
                                )
                                .foregroundColor(selectedCategory == cat ? .white : Color.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            
            Divider().opacity(0.15)
            
            // Grid of Providers (matching reference screenshot)
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(filteredProviders) { item in
                        ProviderGridTile(
                            provider: item,
                            isSelected: editingProviderId == item.id,
                            onTap: {
                                editingProviderId = item.id
                            },
                            onToggle: {
                                if let idx = usageManager.providers.firstIndex(where: { $0.id == item.id }) {
                                    usageManager.providers[idx].isEnabled.toggle()
                                    usageManager.save()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
    }
    
    // MARK: - Tab 2: Dirección y Posición de la Barra
    private var directionPositionTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Direction Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dirección de la Barra y Despliegue")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Selecciona el borde de tu pantalla donde se ancla el dock y la dirección hacia donde se abren las tarjetas de métricas:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        DirectionOptionCard(
                            title: "Izquierda a Derecha",
                            badge: "Borde Izquierdo",
                            iconName: "arrow.right.to.line.compact",
                            description: "El dock se acopla a la orilla izquierda. Las tarjetas de consumo se despliegan hacia la derecha (recomendado).",
                            isSelected: usageManager.position == .leftEdge,
                            onSelect: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    usageManager.position = .leftEdge
                                }
                            }
                        )
                        
                        DirectionOptionCard(
                            title: "Derecha a Izquierda",
                            badge: "Borde Derecho",
                            iconName: "arrow.left.to.line.compact",
                            description: "El dock se acopla a la orilla derecha. Las tarjetas de consumo se despliegan hacia la izquierda.",
                            isSelected: usageManager.position == .rightEdge,
                            onSelect: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    usageManager.position = .rightEdge
                                }
                            }
                        )
                        
                        DirectionOptionCard(
                            title: "Notch Superior",
                            badge: "MacBook Notch",
                            iconName: "arrow.down.to.line.compact",
                            description: "Centrado debajo del notch físico de tu MacBook o en el centro de la barra de menús superior.",
                            isSelected: usageManager.position == .topNotch,
                            onSelect: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                    usageManager.position = .topNotch
                                }
                            }
                        )
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.08)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                
                // Alignment & Height Offset
                if usageManager.position != .topNotch {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Alineación Vertical en el Borde")
                            .font(.system(size: 15, weight: .bold))
                        
                        Picker("Alineación vertical:", selection: $usageManager.edgeAlignment) {
                            ForEach(EdgeAlignment.allCases) { align in
                                Text(align.rawValue).tag(align)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Ajuste fino de altura:")
                                    .font(.system(size: 13))
                                Spacer()
                                Text("\(Int(usageManager.verticalOffset)) px")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                            }
                            
                            Slider(value: $usageManager.verticalOffset, in: -300...300, step: 5)
                                .tint(Color(red: 0.05, green: 0.90, blue: 0.48))
                            
                            HStack {
                                Text("Más abajo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Restablecer al centro (0 px)") {
                                    usageManager.verticalOffset = 0
                                }
                                .buttonStyle(.plain)
                                .font(.caption2)
                                .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                                Spacer()
                                Text("Más arriba")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                
                // Visibility & Collapsed Icon
                VStack(alignment: .leading, spacing: 14) {
                    Text("Comportamiento y Visibilidad")
                        .font(.system(size: 15, weight: .bold))
                    
                    Toggle("Mostrar Usage Notch en pantalla", isOn: $usageManager.isHudVisible)
                        .font(.system(size: 13, weight: .medium))
                    
                    Divider().opacity(0.15)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Herramienta principal en modo reposo:")
                                .font(.system(size: 13, weight: .medium))
                            Text("Icono mostrado al colapsar la barra")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $usageManager.primaryProviderId) {
                            ForEach(usageManager.providers.filter { $0.isEnabled }) { item in
                                HStack {
                                    ProviderBrandIcon(provider: item.id, size: 14, color: .white)
                                    Text(item.id.displayName)
                                }
                                .tag(item.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.08)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .padding(18)
        }
    }
    
    // MARK: - Tab 3: Acerca de
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(white: 0.08))
                    .frame(width: 76, height: 76)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.05, green: 0.90, blue: 0.48), Color(white: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.25), radius: 10)
                
                AntigravityArchIcon(size: 32, color: Color(red: 0.05, green: 0.90, blue: 0.48))
            }
            
            VStack(spacing: 4) {
                Text("Usage Notch")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Versión 1.3.0 (macOS Native)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Text("Monitoreo de consumo y cuotas de IA en tiempo real para más de 35 herramientas, editores y modelos: Codex, Claude, Cursor, Antigravity, Copilot, DeepSeek, Ollama y más.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Divider().frame(width: 200).opacity(0.2)
            
            HStack(spacing: 12) {
                Label("100% Local", systemImage: "lock.shield.fill")
                Text("•")
                Label("120 FPS Metal/SwiftUI", systemImage: "sparkles")
                Text("•")
                Label("Bisel Orgánico", systemImage: "macwindow")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Componente Tile de la Cuadrícula (Estilo captura de referencia)
struct ProviderGridTile: View {
    var provider: ProviderUsage
    var isSelected: Bool
    var onTap: () -> Void
    var onToggle: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 9) {
                // Brand Icon
                ProviderBrandIcon(provider: provider.id, size: 20, color: .white)
                    .frame(width: 24, height: 24)
                
                // Name & Auth Subtitle
                VStack(alignment: .leading, spacing: 1) {
                    Text(provider.id.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(provider.id.authMethod.rawValue)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.52))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 2)
                
                // Active status dot
                Button(action: onToggle) {
                    Circle()
                        .fill(provider.isEnabled ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white.opacity(0.12))
                        .frame(width: 7, height: 7)
                        .shadow(color: provider.isEnabled ? Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.7) : .clear, radius: 4)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .help(provider.isEnabled ? "Desactivar de la barra" : "Activar en la barra")
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isSelected ? Color(white: 0.20) : (isHovering ? Color(white: 0.14) : Color(white: 0.07)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(
                        isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.7) : (isHovering ? Color.white.opacity(0.15) : Color.white.opacity(0.06)),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { h in isHovering = h }
    }
}

// MARK: - Componente Card de Selección de Dirección
struct DirectionOptionCard: View {
    var title: String
    var badge: String
    var iconName: String
    var description: String
    var isSelected: Bool
    var onSelect: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : .white)
                    
                    Spacer()
                    
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48).opacity(0.2) : Color.white.opacity(0.08))
                        )
                        .foregroundColor(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white.opacity(0.65))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 6) {
                    Circle()
                        .strokeBorder(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white.opacity(0.3), lineWidth: 2)
                        .background(Circle().fill(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.clear))
                        .frame(width: 14, height: 14)
                    
                    Text(isSelected ? "Activo" : "Seleccionar")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : Color.white.opacity(0.4))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(white: 0.13) : (isHovering ? Color(white: 0.11) : Color(white: 0.06)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(red: 0.05, green: 0.90, blue: 0.48) : (isHovering ? Color.white.opacity(0.15) : Color.white.opacity(0.07)),
                        lineWidth: isSelected ? 1.8 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { h in isHovering = h }
    }
}

// MARK: - Sheet de Configuración de Proveedor Específico
struct ProviderConfigSheet: View {
    var index: Int
    @ObservedObject var usageManager: UsageManager
    @ObservedObject var apiService: APIUsageService
    var testResult: (success: Bool, message: String)?
    var onTest: () -> Void
    var onDismiss: () -> Void
    
    private var provider: ProviderUsage {
        usageManager.providers[index]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack(spacing: 12) {
                ProviderBrandIcon(provider: provider.id, size: 28, color: .white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(white: 0.15)))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(provider.id.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(provider.id.authMethod.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Text(provider.id.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(Color(white: 0.10))
            
            Divider().opacity(0.2)
            
            // Sheet Body
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Toggle Active in Notch
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mostrar en el Dock / Notch")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Muestra el medidor de consumo de este proveedor en la barra lateral.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $usageManager.providers[index].isEnabled)
                            .labelsHidden()
                            .onChange(of: usageManager.providers[index].isEnabled) { _ in
                                usageManager.save()
                            }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.08)))
                    
                    // Connection Mode
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Método de Monitoreo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Picker("", selection: $usageManager.providers[index].connectionMode) {
                            ForEach(ConnectionMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: usageManager.providers[index].connectionMode) { _ in
                            usageManager.save()
                        }
                    }
                    
                    if provider.connectionMode == .api {
                        // Credentials input section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Credenciales de Conexión")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            
                            credentialInputField
                            
                            HStack {
                                Button(action: onTest) {
                                    HStack(spacing: 6) {
                                        if apiService.testingProviderId == provider.id {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "bolt.fill")
                                        }
                                        Text("Probar Conexión y Guardar")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(red: 0.05, green: 0.90, blue: 0.48))
                                .foregroundColor(.black)
                                .disabled(apiService.testingProviderId == provider.id)
                                
                                Spacer()
                            }
                            
                            if let result = testResult {
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
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.08)))
                    } else {
                        // Manual quota adjustment
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cuota Manual / Plan Pro")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Consumo actual:")
                                Spacer()
                                Text("\(Int(usageManager.providers[index].primaryUsedPercent))%")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.05, green: 0.90, blue: 0.48))
                            }
                            
                            Slider(value: $usageManager.providers[index].primaryUsedPercent, in: 0...100, step: 1)
                                .tint(Color(red: 0.05, green: 0.90, blue: 0.48))
                                .onChange(of: usageManager.providers[index].primaryUsedPercent) { _ in
                                    usageManager.save()
                                }
                            
                            Button("Reiniciar contador a 0% ahora") {
                                usageManager.resetSession(for: usageManager.providers[index].id)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.08)))
                    }
                }
                .padding(18)
            }
            
            Divider().opacity(0.2)
            
            // Sheet Footer
            HStack {
                Spacer()
                Button("Listo") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(white: 0.25))
            }
            .padding(14)
            .background(Color(white: 0.10))
        }
        .frame(width: 520, height: 500)
    }
    
    @ViewBuilder
    private var credentialInputField: some View {
        switch provider.id.authMethod {
        case .oauth:
            VStack(alignment: .leading, spacing: 6) {
                Text("Token de Acceso OAuth o API Key de respaldo:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("Bearer token o sk-...", text: $usageManager.providers[index].apiKeyOrToken)
                    .textFieldStyle(.roundedBorder)
            }
            
        case .cookies, .cookiesGo:
            VStack(alignment: .leading, spacing: 6) {
                Text("Cookie de Sesión:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("Pega tu cookie de sesión del navegador...", text: $usageManager.providers[index].apiKeyOrToken)
                    .textFieldStyle(.roundedBorder)
                Text("Tip: Inicia sesión en el navegador web del servicio, abre DevTools (F12) > Application > Cookies y copia el valor de sesión.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        case .cli, .gcloud, .local:
            VStack(alignment: .leading, spacing: 6) {
                Text("Ruta local o comando:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("auto (detectar en PATH)", text: $usageManager.providers[index].apiKeyOrToken)
                    .textFieldStyle(.roundedBorder)
                Text("Usage Notch consultará la CLI o socket local para obtener estadísticas de uso.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key o Token Secreto:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("sk-...", text: $usageManager.providers[index].apiKeyOrToken)
                    .textFieldStyle(.roundedBorder)
                
                Text("Endpoint personalizado (opcional):")
                    .font(.caption)
                    .padding(.top, 4)
                    .foregroundColor(.secondary)
                TextField("https://api.proveedor.com/v1/usage", text: $usageManager.providers[index].customEndpoint)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

