//
//  StatCard.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(BotanicaTheme.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    StatCard(
        title: "Days Since Last Watering",
        value: "3",
        icon: "drop.fill",
        color: BotanicaTheme.Colors.waterBlue
    )
    .padding()
}