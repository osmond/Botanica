//
//  DetailSection.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            Text(title)
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                content
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(BotanicaTheme.Colors.surface)
            .cornerRadius(BotanicaTheme.CornerRadius.medium)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}

#Preview {
    DetailSection(title: "Plant Information") {
        DetailRow(label: "Scientific Name", value: "Monstera deliciosa")
        DetailRow(label: "Family", value: "Araceae")
        DetailRow(label: "Common Names", value: "Swiss Cheese Plant, Split-leaf Philodendron")
    }
    .padding()
}
