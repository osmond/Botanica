import SwiftUI

struct ReviewStatus {
    let title: String
    let detail: String
    let color: Color
}

struct StatusPill: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(BotanicaTheme.Typography.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, BotanicaTheme.Spacing.sm)
        .padding(.vertical, BotanicaTheme.Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct CareFocusRow: View {
    let plant: Plant
    let status: ReviewStatus
    let onOpen: () -> Void
    let onLogCare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: BotanicaTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                    Text(plant.displayName)
                        .font(BotanicaTheme.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(BotanicaTheme.Colors.textPrimary)

                    Text(status.detail)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }

                Spacer()

                Button("Log care", action: onLogCare)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(BotanicaTheme.Colors.primary)
                    .padding(.horizontal, BotanicaTheme.Spacing.sm)
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                    .background(BotanicaTheme.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            StatusPill(title: status.title, color: status.color)
        }
        .padding(BotanicaTheme.Spacing.cardPadding)
        .background(BotanicaTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(plant.displayName). \(status.detail).")
    }
}

struct PlantReviewRow: View {
    let plant: Plant
    let status: ReviewStatus

    var body: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
            Text(plant.displayName)
                .font(BotanicaTheme.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(BotanicaTheme.Colors.textPrimary)

            Text(status.detail)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)

            StatusPill(title: status.title, color: status.color)
        }
        .padding(.vertical, BotanicaTheme.Spacing.xs)
    }
}

struct CareFocusListView: View {
    let title: String
    let subtitle: String
    let plants: [Plant]
    let statusProvider: (Plant) -> ReviewStatus

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlantForCare: Plant?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(subtitle)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }

                if plants.isEmpty {
                    Text("No plants to review right now.")
                        .font(BotanicaTheme.Typography.callout)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                } else {
                    ForEach(plants, id: \.id) { plant in
                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                            PlantReviewRow(plant: plant, status: statusProvider(plant))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Log care") { selectedPlantForCare = plant }
                                .tint(BotanicaTheme.Colors.primary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedPlantForCare) { plant in
            AddCareEventView(plant: plant)
        }
    }
}
