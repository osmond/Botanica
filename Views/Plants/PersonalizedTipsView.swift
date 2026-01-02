import SwiftUI

struct PersonalizedTipsView: View {
    let plantName: String
    let lightLevel: LightLevel
    let wateringFrequency: Double
    let humidity: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: BotanicaTheme.Spacing.lg) {
                Text("Care Tips for \(plantName)")
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                    .padding(.top)
                
                tipRow(icon: "sun.max.fill", color: BotanicaTheme.Colors.sunYellow, text: lightTip)
                tipRow(icon: "drop.fill", color: BotanicaTheme.Colors.waterBlue, text: waterTip)
                tipRow(icon: "humidity.fill", color: BotanicaTheme.Colors.mintGreen, text: humidityTip)
                
                Spacer()
                Button("Done") { dismiss() }
                    .primaryButtonStyle()
            }
            .padding()
            .navigationTitle("Personalized Tips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var lightTip: String {
        switch lightLevel {
        case .bright: return "Prefers bright, direct sunlight. Place near a south-facing window."
        case .medium: return "Thrives in medium light. Avoid harsh direct sun."
        case .low: return "Can tolerate low light. Good for shaded rooms."
        case .direct:
            // Add appropriate handling for direct light
            return "Prefers direct sunlight. Ensure it gets enough light exposure."
        }
    }
    
    private var waterTip: String {
        if wateringFrequency <= 2 {
            return "Water daily or every other day. Check soil moisture often."
        } else if wateringFrequency <= 7 {
            return "Water weekly. Let the top inch of soil dry out between waterings."
        } else {
            return "Water every 2+ weeks. Ideal for succulents or cacti."
        }
    }
    
    private var humidityTip: String {
        if humidity >= 70 {
            return "Prefers high humidity. Mist leaves or use a humidifier."
        } else if humidity <= 40 {
            return "Tolerates dry air. Avoid overwatering."
        } else {
            return "Average humidity is fine. Keep away from drafts."
        }
    }
    
    @ViewBuilder
    private func tipRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: BotanicaTheme.Spacing.smPlus) {
            Image(systemName: icon)
                .font(BotanicaTheme.Typography.title2)
                .foregroundColor(color)
            Text(text)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}
