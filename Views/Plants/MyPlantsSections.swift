import SwiftUI

/// Compact subviews extracted from MyPlantsView to simplify the main file.
struct CollectionInsightsHeaderView: View {
    let plantsCount: Int
    let collectionHealthPercentage: Int
    let todaysCareCount: Int
    let insight: String
    let summary: String
    let chips: [SmartChip]
    let onChipTap: (SmartChip) -> Void
    let setHealthyFilter: () -> Void
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            HStack(spacing: BotanicaTheme.Spacing.lg) {
                Button {
                    onChipTap(SmartChip(title: "All Plants", count: plantsCount, filter: nil, isSelected: false))
                } label: {
                    ModernStatCard(
                        title: "Plants",
                        value: "\(plantsCount)",
                        icon: "leaf.fill",
                        color: BotanicaTheme.Colors.leafGreen
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    setHealthyFilter()
                } label: {
                    ModernStatCard(
                        title: "Healthy",
                        value: "\(collectionHealthPercentage)%",
                        icon: "heart.fill",
                        color: BotanicaTheme.Colors.success
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    onChipTap(SmartChip(title: "Due Today", count: todaysCareCount, filter: .dueToday, isSelected: false))
                } label: {
                    ModernStatCard(
                        title: "Care Today",
                        value: "\(todaysCareCount)",
                        icon: "drop.fill",
                        color: todaysCareCount > 0 ? BotanicaTheme.Colors.waterBlue : BotanicaTheme.Colors.textTertiary
                    )
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight)
                        .font(BotanicaTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                    Text(summary)
                        .font(BotanicaTheme.Typography.bodyEmphasized)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        ForEach(chips, id: \.title) { chip in
                            QuickFilterPill(
                                title: chip.title,
                                count: chip.count,
                                isSelected: chip.isSelected,
                                action: { onChipTap(chip) }
                            )
                        }
                    }
                    .padding(.vertical, BotanicaTheme.Spacing.xs)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.large)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
    }
}

struct SmartChip {
    let title: String
    let count: Int
    let filter: CareNeededFilter?
    let isSelected: Bool
}

struct CareRemindersSectionView: View {
    let urgentPlants: [Plant]
    let onViewAll: () -> Void
    
    var body: some View {
        EmptyView()
    }
}

struct QuickFiltersView: View {
    @Binding var filterBy: HealthStatus?
    @Binding var careNeededFilter: CareNeededFilter?
    @Binding var sortBy: SortOption
    let plantsCount: Int
    let needsWaterCount: Int
    let needsFertilizerCount: Int
    let dueTodayCount: Int
    let healthyPlantCount: Int
    let weeklyAddedCount: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BotanicaTheme.Spacing.md) {
                QuickFilterPill(
                    title: "All Plants",
                    count: plantsCount,
                    isSelected: filterBy == nil && careNeededFilter == nil,
                    action: { filterBy = nil; careNeededFilter = nil }
                )
                
                QuickFilterPill(
                    title: "Need Water",
                    count: needsWaterCount,
                    isSelected: careNeededFilter == .needsWatering,
                    action: { careNeededFilter = careNeededFilter == .needsWatering ? nil : .needsWatering }
                )
                
                QuickFilterPill(
                    title: "Need Feed",
                    count: needsFertilizerCount,
                    isSelected: careNeededFilter == .needsFertilizing,
                    action: { careNeededFilter = careNeededFilter == .needsFertilizing ? nil : .needsFertilizing }
                )
                
                QuickFilterPill(
                    title: "Due Today",
                    count: dueTodayCount,
                    isSelected: careNeededFilter == .dueToday,
                    action: { careNeededFilter = careNeededFilter == .dueToday ? nil : .dueToday }
                )
                
                QuickFilterPill(
                    title: "Healthy",
                    count: healthyPlantCount,
                    isSelected: filterBy == .healthy,
                    action: { filterBy = filterBy == .healthy ? nil : .healthy }
                )
                
                QuickFilterPill(
                    title: "New",
                    count: weeklyAddedCount,
                    isSelected: sortBy == .dateAdded,
                    action: { sortBy = .dateAdded }
                )
            }
            .padding(.horizontal, BotanicaTheme.Spacing.lg)
        }
    }
}

struct ModernEmptyStateView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.xxl) {
            Spacer()
            
            VStack(spacing: BotanicaTheme.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BotanicaTheme.Colors.leafGreen.opacity(0.15),
                                    BotanicaTheme.Colors.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    VStack(spacing: BotanicaTheme.Spacing.sm) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(BotanicaTheme.Colors.primary)
                            .breatheRepeating()
                        
                        Text("🌱")
                            .font(.system(size: 24))
                    }
                }
                
                VStack(spacing: BotanicaTheme.Spacing.lg) {
                    Text("Start Your Plant Journey")
                        .font(BotanicaTheme.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(BotanicaTheme.Colors.textPrimary)
                    
                    Text("Transform your space into a thriving garden. Track care schedules, monitor plant health, and watch your green family grow.")
                        .font(BotanicaTheme.Typography.body)
                        .foregroundStyle(BotanicaTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BotanicaTheme.Spacing.xl)
                }
                
                Button {
                    onAdd()
                } label: {
                    HStack(spacing: BotanicaTheme.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Your First Plant")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, BotanicaTheme.Spacing.xl)
                    .padding(.vertical, BotanicaTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: BotanicaTheme.CornerRadius.xlarge)
                            .fill(BotanicaTheme.Colors.primary)
                    )
                }
                .scaleEffect(1.0)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(BotanicaTheme.Spacing.xl)
    }
}

struct PlantsMainContentView: View {
    let groups: [PlantGroup]
    let viewMode: ViewMode
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.xl) {
            ForEach(groups, id: \.id) { group in
                ModernPlantSection(
                    group: group,
                    viewMode: viewMode
                )
            }
        }
        .padding(.horizontal, BotanicaTheme.Spacing.lg)
    }
}
