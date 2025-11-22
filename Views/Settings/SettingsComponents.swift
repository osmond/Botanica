//
//  SettingsComponents.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Settings Action Row

struct SettingsActionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BotanicaTheme.Typography.subheadline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Info Row

struct SettingsInfoRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let value: String
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, value: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.value = value
    }
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Value
            Text(value)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Settings Picker Row

struct SettingsPickerRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    @Binding var selection: String
    let options: [(String, String)] // (value, display name)
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, selection: Binding<String>, options: [(String, String)]) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self._selection = selection
        self.options = options
    }
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Picker
            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Settings Link Row

struct SettingsLinkRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let url: String
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, url: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.url = url
    }
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
            HapticManager.shared.light()
        } label: {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BotanicaTheme.Typography.subheadline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(BotanicaTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // External link icon
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        Section("Toggles") {
            SettingsToggleRow(
                title: "Enable Notifications",
                subtitle: "Receive care reminders and updates",
                icon: "bell.fill",
                color: BotanicaTheme.Colors.primary,
                isOn: .constant(true)
            )
        }
        
        Section("Actions") {
            SettingsActionRow(
                title: "AI Plant Coach",
                subtitle: "Configure OpenAI integration",
                icon: "brain.head.profile.fill",
                color: BotanicaTheme.Colors.primary
            ) {
                print("Tapped!")
            }
        }
        
        Section("Info") {
            SettingsInfoRow(
                title: "Plant Identification",
                subtitle: "AI-powered plant recognition",
                icon: "camera.viewfinder",
                color: BotanicaTheme.Colors.leafGreen,
                value: "Enabled"
            )
        }
        
        Section("Pickers") {
            SettingsPickerRow(
                title: "Default Plant View",
                subtitle: "How plants are displayed",
                icon: "square.grid.2x2",
                color: BotanicaTheme.Colors.leafGreen,
                selection: .constant("grid"),
                options: [
                    ("grid", "Grid View"),
                    ("list", "List View")
                ]
            )
        }
    }
}