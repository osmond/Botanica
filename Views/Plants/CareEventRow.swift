//
//  CareEventRow.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

struct CareEventRow: View {
    let event: CareEvent
    
    private var typeIcon: String {
        switch event.type {
        case .watering:
            return "drop.fill"
        case .fertilizing:
            return "leaf.arrow.circlepath"
        case .repotting:
            return "move.3d"
        case .pruning:
            return "scissors"
        case .inspection:
            return "magnifyingglass"
        case .cleaning:
            return "sparkles"
        case .rotating:
            return "arrow.triangle.2.circlepath"
        case .misting:
            return "cloud.drizzle"
        }
    }
    
    private var typeColor: Color {
        switch event.type {
        case .watering:
            return BotanicaTheme.Colors.waterBlue
        case .fertilizing:
            return BotanicaTheme.Colors.nutrientOrange
        case .repotting:
            return BotanicaTheme.Colors.soilBrown
        case .pruning:
            return BotanicaTheme.Colors.leafGreen
        case .inspection:
            return BotanicaTheme.Colors.primary
        case .cleaning:
            return .gray
        case .rotating:
            return .purple
        case .misting:
            return .blue.opacity(0.7)
        }
    }
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            // Type icon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: typeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(typeColor)
            }
            
            // Event details
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                HStack {
                    Text(event.type.rawValue.capitalized)
                        .font(BotanicaTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(event.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let amount = event.amount {
                    Text("Amount: \(amount, specifier: "%.1f")")
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, BotanicaTheme.Spacing.sm)
    }
}

#Preview {
    VStack {
        CareEventRow(event: CareEvent(
            type: .watering,
            date: Date(),
            amount: 250.0,
            notes: "Soil was dry, gave it a good drink"
        ))
        
        CareEventRow(event: CareEvent(
            type: .fertilizing,
            date: Date().addingTimeInterval(-86400),
            notes: "Monthly liquid fertilizer"
        ))
        
        CareEventRow(event: CareEvent(
            type: .inspection,
            date: Date().addingTimeInterval(-172800),
            notes: "Checked for pests, all looking good"
        ))
    }
    .padding()
}