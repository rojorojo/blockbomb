import SwiftUI

#if DEBUG
/// Debug view for multiplayer configuration and testing
struct MultiplayerConfigDebugView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var config = MultiplayerConfig.shared
    @State private var selectedCategory: MultiplayerConfigCategory = .matchSettings
    @State private var showImportExport = false
    @State private var showDebugScenarios = false
    @State private var exportedConfig: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Category Selector
                    categorySelector
                    
                    // Configuration List
                    configurationList
                    
                    // Action Buttons
                    actionButtons
                }
            }
            .navigationTitle("Multiplayer Config")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button("Debug") {
                        showDebugScenarios = true
                    }
                    .foregroundColor(.red)
                    
                    Button("Export") {
                        showImportExport = true
                    }
                    .foregroundColor(.blue)
                }
            )
        }
        .sheet(isPresented: $showImportExport) {
            ImportExportView(config: config, exportedConfig: $exportedConfig)
        }
        .actionSheet(isPresented: $showDebugScenarios) {
            debugScenariosActionSheet
        }
    }
    
    // MARK: - View Components
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MultiplayerConfigCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.systemImage)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? category.color : Color.gray.opacity(0.3))
                        )
                        .foregroundColor(selectedCategory == category ? .white : .gray)
                    }
                    .accessibilityLabel("\(category.displayName) configuration category")
                    .accessibilityHint("Tap to view settings for \(category.displayName)")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var configurationList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(keysForCategory(selectedCategory), id: \.self) { key in
                    ConfigurationRow(key: key, config: config)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: {
                    resetCategoryToDefaults()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Category")
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }
                .accessibilityLabel("Reset \(selectedCategory.displayName) settings to defaults")
                
                Button(action: {
                    config.resetAllToDefaults()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset All")
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                }
                .accessibilityLabel("Reset all multiplayer settings to defaults")
            }
            
            // Game Center Status
            HStack {
                Image(systemName: config.gameCenterAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(config.gameCenterAvailable ? .green : .red)
                Text("Game Center: \(config.gameCenterAvailable ? "Available" : "Unavailable")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private var debugScenariosActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Debug Scenarios"),
            message: Text("Apply preset configurations for testing"),
            buttons: [
                .default(Text("Fast Matches")) {
                    config.debugMultiplayer(scenario: .fastMatches)
                },
                .default(Text("Connection Testing")) {
                    config.debugMultiplayer(scenario: .connectionTesting)
                },
                .default(Text("Scoring Testing")) {
                    config.debugMultiplayer(scenario: .scoringTesting)
                },
                .default(Text("Privacy Testing")) {
                    config.debugMultiplayer(scenario: .privacyTesting)
                },
                .default(Text("High Performance")) {
                    config.debugMultiplayer(scenario: .highPerformance)
                },
                .destructive(Text("Reset to Defaults")) {
                    config.debugMultiplayer(scenario: .resetToDefaults)
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private func keysForCategory(_ category: MultiplayerConfigCategory) -> [MultiplayerConfigKey] {
        return MultiplayerConfigKey.allCases.filter { $0.category == category }
    }
    
    private func resetCategoryToDefaults() {
        for key in keysForCategory(selectedCategory) {
            config.resetToDefault(key: key)
        }
    }
}

// MARK: - Configuration Row

struct ConfigurationRow: View {
    let key: MultiplayerConfigKey
    @ObservedObject var config: MultiplayerConfig
    @State private var editingValue = ""
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(key.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(key.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if key.isBoolean {
                    Toggle("", isOn: Binding(
                        get: { config.getBoolValue(for: key) },
                        set: { config.setValue($0 ? 1 : 0, for: key) }
                    ))
                    .accessibilityLabel(key.displayName)
                    .accessibilityValue(config.getBoolValue(for: key) ? "On" : "Off")
                } else {
                    configValueEditor
                }
            }
            
            // Show current vs default indicator
            if !(config.configValues[key]?.isDefault ?? true) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Modified")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Default") {
                        config.resetToDefault(key: key)
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(config.getAccessibilityDescription(for: key))
    }
    
    private var configValueEditor: some View {
        HStack {
            if isEditing {
                TextField("Value", text: $editingValue, onCommit: {
                    if let value = Int(editingValue) {
                        config.setValue(value, for: key)
                    }
                    isEditing = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .keyboardType(.numberPad)
                .accessibilityLabel("Enter new value for \(key.displayName)")
            } else {
                Text("\(config.getValue(for: key))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .onTapGesture {
                        editingValue = "\(config.getValue(for: key))"
                        isEditing = true
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Current value: \(config.getValue(for: key)). Tap to edit.")
            }
        }
    }
}

// MARK: - Import/Export View

struct ImportExportView: View {
    @Environment(\.presentationMode) var presentationMode
    let config: MultiplayerConfig
    @Binding var exportedConfig: String
    @State private var importText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Configuration")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button("Generate Export") {
                        exportConfiguration()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    if !exportedConfig.isEmpty {
                        ScrollView {
                            Text(exportedConfig)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // Import Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import Configuration")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $importText)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(height: 150)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .accessibilityLabel("Configuration import text area")
                    
                    Button("Import Configuration") {
                        importConfiguration()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(red: 0.02, green: 0, blue: 0.22, opacity: 1))
            .navigationTitle("Import/Export")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Configuration"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func exportConfiguration() {
        if let data = config.exportConfiguration(),
           let jsonString = String(data: data, encoding: .utf8) {
            exportedConfig = jsonString
        } else {
            alertMessage = "Failed to export configuration"
            showAlert = true
        }
    }
    
    private func importConfiguration() {
        guard !importText.isEmpty else {
            alertMessage = "Please enter configuration JSON"
            showAlert = true
            return
        }
        
        guard let data = importText.data(using: .utf8) else {
            alertMessage = "Invalid text format"
            showAlert = true
            return
        }
        
        if config.importConfiguration(from: data) {
            alertMessage = "Configuration imported successfully"
            importText = ""
        } else {
            alertMessage = "Failed to import configuration. Check JSON format."
        }
        showAlert = true
    }
}

#endif
