import SwiftUI

enum BotanicalSeason: String, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    
    static var current: BotanicalSeason {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
    
    var careModifications: String {
        switch self {
        case .spring:
            return "Resume steady watering, watch for new growth, and refresh soil if needed."
        case .summer:
            return "Water more consistently, monitor light intensity, and keep humidity stable."
        case .fall:
            return "Ease off watering, reduce feeding, and check for temperature swings."
        case .winter:
            return "Water less often, pause feeding, and focus on light and humidity."
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .spring: return BotanicaTheme.Colors.leafGreen
        case .summer: return BotanicaTheme.Colors.sunYellow
        case .fall: return BotanicaTheme.Colors.terracotta
        case .winter: return BotanicaTheme.Colors.waterBlue
        }
    }
    
    var tips: [String] {
        switch self {
        case .spring:
            return [
                "Increase watering gradually as days lengthen.",
                "Rotate plants to balance new growth.",
                "Repot if roots are crowded."
            ]
        case .summer:
            return [
                "Check soil moisture more often.",
                "Protect from direct, harsh afternoon sun.",
                "Mist or group plants to support humidity."
            ]
        case .fall:
            return [
                "Trim back on fertilizer.",
                "Watch for cooler drafts near windows.",
                "Let the topsoil dry a bit more between waterings."
            ]
        case .winter:
            return [
                "Space out watering intervals.",
                "Keep leaves clean for low-light conditions.",
                "Avoid cold water on roots."
            ]
        }
    }
}

struct SeasonalCareGuidanceView: View {
    let plants: [Plant]
    
    private var currentSeason: BotanicalSeason {
        BotanicalSeason.current
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                    Text("\(currentSeason.rawValue) Care Guidance")
                        .font(BotanicaTheme.Typography.title1)
                        .fontWeight(.bold)
                    Text(currentSeason.careModifications)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    Text("Seasonal Focus")
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                        ForEach(currentSeason.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: BotanicaTheme.Spacing.sm) {
                                Circle()
                                    .fill(currentSeason.primaryColor)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, BotanicaTheme.Spacing.sm)
                                Text(tip)
                                    .font(BotanicaTheme.Typography.body)
                                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                            }
                        }
                    }
                }
                .padding(BotanicaTheme.Spacing.lg)
                .background(BotanicaTheme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large))
                
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
                    Text("Plants to Review")
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.semibold)
                    
                    if plants.isEmpty {
                        Text("Add plants to receive seasonal guidance.")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                    } else {
                        VStack(spacing: BotanicaTheme.Spacing.md) {
                            ForEach(plants.prefix(6), id: \.id) { plant in
                                HStack {
                                    VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                                        Text(plant.displayName)
                                            .font(BotanicaTheme.Typography.subheadline)
                                            .foregroundColor(BotanicaTheme.Colors.textPrimary)
                                        Text(nextCareLine(for: plant))
                                            .font(BotanicaTheme.Typography.caption)
                                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(BotanicaTheme.Typography.caption)
                                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                                }
                                .padding(BotanicaTheme.Spacing.md)
                                .background(BotanicaTheme.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium))
                            }
                        }
                    }
                }
            }
            .padding(BotanicaTheme.Spacing.lg)
        }
        .navigationTitle("Seasonal Guidance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func nextCareLine(for plant: Plant) -> String {
        if let date = plant.nextWateringDate {
            return "Next watering \(date.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Review schedule and conditions"
    }
}
