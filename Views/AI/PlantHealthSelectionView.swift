import SwiftUI
import SwiftData

/// Plant selection view for health analysis
struct PlantHealthSelectionView: View {
    @Query private var plants: [Plant]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: BotanicaTheme.Spacing.lg) {
                if plants.isEmpty {
                    VStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: BotanicaTheme.Sizing.iconJumbo))
                            .foregroundColor(BotanicaTheme.Colors.leafGreen)
                        
                        Text("No Plants Yet")
                            .font(BotanicaTheme.Typography.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add your first plant to get started with AI health analysis")
                            .font(BotanicaTheme.Typography.body)
                            .foregroundColor(BotanicaTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: BotanicaTheme.Spacing.md) {
                            ForEach(plants) { plant in
                                NavigationLink(destination: PlantHealthVisionView(plant: plant)) {
                                    PlantHealthCard(plant: plant)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Select Plant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlantHealthCard: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: BotanicaTheme.Spacing.md) {
            // Plant image or icon
            ZStack {
                Circle()
                    .fill(BotanicaTheme.Colors.leafGreen.opacity(0.1))
                    .frame(width: BotanicaTheme.Sizing.iconJumbo, height: BotanicaTheme.Sizing.iconJumbo)
                
                if let photoData = plant.photos.first?.imageData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: BotanicaTheme.Sizing.iconJumbo, height: BotanicaTheme.Sizing.iconJumbo)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "leaf.fill")
                        .font(BotanicaTheme.Typography.title2)
                        .foregroundColor(BotanicaTheme.Colors.leafGreen)
                }
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.xs) {
                Text(plant.displayName)
                    .font(BotanicaTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(BotanicaTheme.Colors.textPrimary)
                
                Text(plant.scientificName)
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(BotanicaTheme.Colors.textSecondary)
                
                // Health status indicator
                HStack(spacing: BotanicaTheme.Spacing.sm) {
                    Circle()
                        .fill(plant.healthStatusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(plant.healthStatus.rawValue)
                        .font(BotanicaTheme.Typography.caption)
                        .foregroundColor(BotanicaTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(BotanicaTheme.Colors.textSecondary)
        }
        .padding(BotanicaTheme.Spacing.md)
        .cardStyle()
    }
}

#Preview {
    PlantHealthSelectionView()
        .modelContainer(MockDataGenerator.previewContainer())
}
