import SwiftUI
import Combine

#if DEBUG
/// Debug configuration view for real-time reward economy tuning
struct RewardConfigDebugView: View {
    @ObservedObject private var rewardConfig = RewardConfig.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var exportedConfigString = ""
    @State private var selectedCategory: RewardConfigCategory = .currency
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.02, green: 0, blue: 0.22, opacity: 1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    headerSection
                    categoryPicker
                    configurationList
                    actionButtons
                    
                    Spacer()
                    closeButton
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Exported Configuration", isPresented: $showingExportAlert) {
            Button("Copy to Clipboard") {
                UIPasteboard.general.string = exportedConfigString
            }
            Button("OK") { }
        } message: {
            Text("Configuration has been exported to JSON format.")
        }
        .alert("Import Configuration", isPresented: $showingImportAlert) {
            Button("From Clipboard") {
                importFromClipboard()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Import configuration from clipboard JSON data?")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Reward Config Debug")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(BlockColors.violet)
                .padding(.top, 20)
            
            if let lastUpdate = rewardConfig.lastUpdateTimestamp {
                Text("Last updated: \(lastUpdate, style: .time)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(RewardConfigCategory.allCases, id: \.self) { category in
                Text(category.displayName)
                    .tag(category)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var configurationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(configKeysForCategory(selectedCategory), id: \.self) { key in
                    ConfigurationItemView(
                        key: key,
                        currentValue: rewardConfig.getValue(for: key),
                        isDefault: rewardConfig.configValues[key]?.isDefault ?? true,
                        onValueChanged: { newValue in
                            rewardConfig.setValue(newValue, for: key)
                        },
                        onResetToDefault: {
                            rewardConfig.resetToDefault(key: key)
                        }
                    )
                }
            }
            .padding(.vertical)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                DebugActionButton(
                    title: "Test Preset",
                    subtitle: "Apply testing values",
                    color: .green,
                    action: {
                        rewardConfig.debugApplyTestPreset()
                    }
                )
                
                DebugActionButton(
                    title: "Production Preset",
                    subtitle: "Apply production values",
                    color: .blue,
                    action: {
                        rewardConfig.debugApplyProductionPreset()
                    }
                )
            }
            
            HStack(spacing: 12) {
                DebugActionButton(
                    title: "Export Config",
                    subtitle: "Export as JSON",
                    color: .orange,
                    action: exportConfiguration
                )
                
                DebugActionButton(
                    title: "Import Config",
                    subtitle: "Import from JSON",
                    color: .purple,
                    action: {
                        showingImportAlert = true
                    }
                )
            }
            
            DebugActionButton(
                title: "Reset All to Defaults",
                subtitle: "Restore all default values",
                color: .red,
                action: {
                    rewardConfig.resetAllToDefaults()
                }
            )
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Close")
                .font(.title2.bold())
                .foregroundColor(Color(red: 0.13, green: 0.12, blue: 0.28))
                .frame(width: 200, height: 50)
                .background(BlockColors.violet)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func configKeysForCategory(_ category: RewardConfigCategory) -> [RewardConfigKey] {
        return RewardConfigKey.allCases.filter { $0.category == category }
    }
    
    private func exportConfiguration() {
        guard let data = rewardConfig.exportConfiguration(),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to export configuration")
            return
        }
        
        exportedConfigString = jsonString
        showingExportAlert = true
    }
    
    private func importFromClipboard() {
        guard let clipboardString = UIPasteboard.general.string,
              let data = clipboardString.data(using: .utf8) else {
            print("No valid JSON data in clipboard")
            return
        }
        
        let success = rewardConfig.importConfiguration(from: data)
        print("Import \(success ? "successful" : "failed")")
    }
}

/// Individual configuration item view with editing capabilities
struct ConfigurationItemView: View {
    let key: RewardConfigKey
    let currentValue: Int
    let isDefault: Bool
    let onValueChanged: (Int) -> Void
    let onResetToDefault: () -> Void
    
    @State private var editingValue = ""
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(key.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(key.category.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(key.category.color.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(key.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Value display/editor
                if isEditing {
                    HStack {
                        TextField("Value", text: $editingValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .keyboardType(.numberPad)
                        
                        Button("Save") {
                            if let newValue = Int(editingValue) {
                                onValueChanged(newValue)
                            }
                            isEditing = false
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                        
                        Button("Cancel") {
                            isEditing = false
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                } else {
                    HStack {
                        Text("\(currentValue)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(key.category.color)
                            .frame(minWidth: 40, alignment: .trailing)
                        
                        Button(action: {
                            editingValue = "\(currentValue)"
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                if !isDefault {
                    Button("Reset to Default") {
                        onResetToDefault()
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(key.category.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// Debug action button for configuration operations
struct DebugActionButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RewardConfigDebugView_Previews: PreviewProvider {
    static var previews: some View {
        RewardConfigDebugView()
    }
}

#endif
