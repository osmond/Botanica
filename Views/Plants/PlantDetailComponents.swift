//
//  PlantDetailComponents.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI
import SwiftData

struct CareStateCard: View {
    let statusType: PlantDetailViewModel.CareStatusType
    let title: String
    let subtitle: String
    let meta: String?
    let cta: PlantDetailViewModel.CareCTA?
    let onCTATap: ((PlantDetailViewModel.CareActionType) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(BotanicaTheme.Colors.textPrimary)

                Spacer(minLength: 8)

                if statusType == .needsAction, let cta, let onCTATap {
                    let buttonColor: Color = {
                        switch cta.actionType {
                        case .logWater:
                            return BotanicaTheme.Colors.waterBlue
                        case .logFertilize:
                            return BotanicaTheme.Colors.leafGreen
                        }
                    }()
                    Button {
                        onCTATap(cta.actionType)
                    } label: {
                        Text(cta.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, BotanicaTheme.Spacing.md)
                            .padding(.vertical, 8)
                            .background(buttonColor)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(cta.label)
                }
            }

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                .lineLimit(1)

            if let meta {
                Text(meta)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BotanicaTheme.Colors.textSecondary.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium)
                .stroke(statusType == .needsAction ? BotanicaTheme.Colors.waterBlue.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 5)
    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, configurations: config)
    let context = container.mainContext
    let plant = MockDataGenerator.shared.createSamplePlants().first!
    context.insert(plant)
    AddCareEventView(plant: plant)
        .modelContainer(container)
}
#endif
