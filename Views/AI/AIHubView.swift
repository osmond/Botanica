import SwiftUI
import SwiftData

struct AIHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Identify") {
                    NavigationLink {
                        PlantIdentificationView()
                    } label: {
                        AIHubRow(
                            title: "Plant Identification",
                            subtitle: "Identify a plant from a photo",
                            icon: "camera.viewfinder",
                            color: BotanicaTheme.Colors.primary
                        )
                    }
                }
                
                Section("Care") {
                    NavigationLink {
                        AIPlantPickerView(
                            title: "AI Plant Coach",
                            emptyTitle: "No Plants Yet",
                            emptySubtitle: "Add a plant to start a chat with your AI coach."
                        ) { plant in
                            AICoachView(plant: plant)
                        }
                    } label: {
                        AIHubRow(
                            title: "AI Plant Coach",
                            subtitle: "Ask questions and get advice",
                            icon: "message.badge.waveform",
                            color: BotanicaTheme.Colors.leafGreen
                        )
                    }
                    
                    NavigationLink {
                        AIPlantPickerView(
                            title: "AI Care Assistant",
                            emptyTitle: "No Plants Yet",
                            emptySubtitle: "Add a plant to generate care plans and diagnostics."
                        ) { plant in
                            AICareAssistantView(plant: plant)
                        }
                    } label: {
                        AIHubRow(
                            title: "AI Care Assistant",
                            subtitle: "Plans, questions, and diagnosis",
                            icon: "wand.and.stars",
                            color: BotanicaTheme.Colors.waterBlue
                        )
                    }
                }
                
                Section("Health") {
                    NavigationLink {
                        PlantHealthSelectionView()
                    } label: {
                        AIHubRow(
                            title: "Health Vision",
                            subtitle: "Analyze plant health with photos",
                            icon: "stethoscope",
                            color: BotanicaTheme.Colors.warning
                        )
                    }
                }
                
                Section("Settings") {
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        AIHubRow(
                            title: "AI Settings",
                            subtitle: "Configure OpenAI and AI features",
                            icon: "gearshape.fill",
                            color: BotanicaTheme.Colors.terracotta
                        )
                    }
                }
            }
            .navigationTitle("AI")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct AIHubRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct AIPlantPickerView<Destination: View>: View {
    let title: String
    let emptyTitle: String
    let emptySubtitle: String
    let destination: (Plant) -> Destination
    
    @Query private var plants: [Plant]
    
    var body: some View {
        List {
            if plants.isEmpty {
                VStack(spacing: BotanicaTheme.Spacing.md) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 52))
                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                    Text(emptyTitle)
                        .font(BotanicaTheme.Typography.title3)
                        .fontWeight(.semibold)
                    Text(emptySubtitle)
                        .font(BotanicaTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(BotanicaTheme.Spacing.xl)
                .listRowSeparator(.hidden)
            } else {
                ForEach(plants) { plant in
                    NavigationLink {
                        destination(plant)
                    } label: {
                        HStack(spacing: BotanicaTheme.Spacing.md) {
                            AsyncPlantThumbnail(photo: plant.primaryPhoto, plant: plant, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plant.displayName)
                                    .font(BotanicaTheme.Typography.subheadline)
                                    .foregroundColor(.primary)
                                Text(plant.scientificName)
                                    .font(BotanicaTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    AIHubView()
        .modelContainer(MockDataGenerator.previewContainer())
}
